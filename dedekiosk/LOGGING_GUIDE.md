# Logging Guide - DeDe Kiosk

**Version:** 1.0
**Purpose:** Debug-only logging that won't appear in production builds

---

## 🎯 Overview

The new logging system ensures that **all log messages only appear in debug mode** and are automatically stripped out in production builds. This improves performance and reduces APK size.

### Key Benefits:
- ✅ **Zero performance impact** in production
- ✅ **Smaller APK size** (no log strings in release)
- ✅ **Better organization** with tags and levels
- ✅ **Easy to use** - simpler than `if (kDebugMode) { print() }`

---

## 📚 How to Use

### 1. Import the Logger

```dart
import 'package:dedekiosk/util/logger.dart';
```

### 2. Use Logger Methods

#### Debug Messages (General debugging)
```dart
Logger.d('User tapped on product');
Logger.d('Category loaded: ${category.name}', tag: 'Category');
```

#### Info Messages (Important information)
```dart
Logger.i('Order completed successfully');
Logger.i('Payment received: $amount THB', tag: 'Payment');
```

#### Warning Messages (Potential issues)
```dart
Logger.w('Image failed to load, using fallback');
Logger.w('Low memory warning: ${memory}MB', tag: 'Performance');
```

#### Error Messages (Errors with stack traces)
```dart
try {
  await processPayment();
} catch (e, s) {
  Logger.e('Payment processing failed',
    tag: 'Payment',
    error: e,
    stackTrace: s
  );
}
```

#### Performance Messages (Performance debugging)
```dart
Logger.perf('Product list loaded in 250ms', tag: 'Performance');
```

#### Network Messages (API calls)
```dart
Logger.network('POST /api/orders - 200 OK', tag: 'API');
Logger.network('Failed to connect to server', tag: 'API');
```

---

## 🔄 Migration from print()

### Before (Old way):
```dart
// ❌ Old way - always prints, even in production
if (kDebugMode) {
  print('Shop ID: ${global.deviceConfig.shopId}');
}

// ❌ Even worse - prints in production!
print('Error: $e');
```

### After (New way):
```dart
// ✅ New way - only in debug mode
Logger.d('Shop ID: ${global.deviceConfig.shopId}', tag: 'Config');

// ✅ Error logging with stack trace
Logger.e('Error occurred', error: e, stackTrace: s);
```

---

## 🏷️ Recommended Tags

Use tags to categorize your logs:

| Tag | Use For |
|-----|---------|
| `Category` | Category-related operations |
| `Product` | Product loading/display |
| `Order` | Order processing |
| `Payment` | Payment operations |
| `Print` | Printing operations |
| `API` | Network/API calls |
| `BLoC` | BLoC state changes |
| `Performance` | Performance measurements |
| `Database` | Database operations |
| `Config` | Configuration loading |

### Example:
```dart
Logger.i('Loading categories', tag: 'Category');
Logger.d('API request: POST /orders', tag: 'API');
Logger.perf('Image cache hit: 95%', tag: 'Performance');
```

---

## ⏱️ Performance Timing

Use `LogTimer` to measure execution time:

```dart
final timer = Logger.startTimer('Load Product List');

// ... do expensive operation
await loadProducts();

timer.stop(); // Logs: "Load Product List took 250ms"
```

---

## 🎨 Log Output Format

All logs are prefixed with `[DeDe Kiosk]` for easy filtering:

```
[DeDe Kiosk][Payment] [DEBUG] Processing payment for 150.00 THB
[DeDe Kiosk][API] [INFO] Order submitted successfully
[DeDe Kiosk][Performance] [PERF] ⚡ Image loading took 45ms
[DeDe Kiosk][Payment] [WARN] ⚠️ Payment timeout, retrying...
[DeDe Kiosk][Order] [ERROR] ❌ Failed to save order
```

---

## 🔍 Filtering Logs

### In Android Studio / VS Code:
```
Search logs for: [DeDe Kiosk]
Filter by tag: [DeDe Kiosk][Payment]
Filter by level: [ERROR]
```

### In Terminal:
```bash
# All DeDe Kiosk logs
flutter run | grep "DeDe Kiosk"

# Only errors
flutter run | grep "\[ERROR\]"

# Specific tag
flutter run | grep "\[Payment\]"
```

---

## 📊 Common Patterns

### 1. API Call Logging
```dart
Future<void> submitOrder() async {
  Logger.network('POST /api/orders', tag: 'API');

  try {
    final response = await api.submitOrder(order);
    Logger.i('Order submitted: ${response.orderId}', tag: 'Order');
  } catch (e, s) {
    Logger.e('API call failed', tag: 'API', error: e, stackTrace: s);
  }
}
```

### 2. BLoC State Logging
```dart
@override
Stream<OrderState> mapEventToState(OrderEvent event) async* {
  if (event is LoadOrder) {
    Logger.d('Loading order: ${event.orderId}', tag: 'BLoC');

    try {
      final order = await repository.getOrder(event.orderId);
      Logger.i('Order loaded successfully', tag: 'BLoC');
      yield OrderLoaded(order);
    } catch (e, s) {
      Logger.e('Failed to load order', tag: 'BLoC', error: e, stackTrace: s);
      yield OrderError(e.toString());
    }
  }
}
```

### 3. Performance Monitoring
```dart
Future<void> loadProducts() async {
  final timer = Logger.startTimer('Load Products');

  try {
    final products = await api.getProducts();
    Logger.i('Loaded ${products.length} products', tag: 'Product');
  } finally {
    timer.stop(); // Logs execution time
  }
}
```

### 4. Error Handling
```dart
try {
  await processPayment(amount);
} catch (e, s) {
  // Log error with full context
  Logger.e(
    'Payment failed for amount: $amount',
    tag: 'Payment',
    error: e,
    stackTrace: s,
  );

  // Show user-friendly message
  showErrorDialog(context, 'การชำระเงินล้มเหลว');
}
```

---

## ✅ Migration Checklist

### Files with Most print() statements:
- [ ] `lib/global.dart` - 40 prints
- [ ] `lib/util/api.dart` - 36 prints
- [ ] `lib/main.dart` - 16 prints
- [ ] `lib/order/pay_creditcard_page.dart` - 15 prints
- [ ] `lib/order/pay_qr_payment_page.dart` - 15 prints
- [ ] `lib/order/pay_qr_edc_page.dart` - 15 prints
- [ ] `lib/print/print.dart` - 19 prints
- [ ] `lib/order/order_save.dart` - 13 prints
- [ ] Other files...

### Replacement Pattern:
```dart
// BEFORE
if (kDebugMode) {
  print('Message');
}

// AFTER
Logger.d('Message');
```

---

## 🚀 Automated Migration

We've created a Python script to help migrate:

```bash
python replace_prints.py
```

This will:
1. Add logger import to files
2. Replace `if (kDebugMode) { print() }` with `Logger.d()`
3. Create `.bak` backup files
4. Show summary of changes

**Note:** Review changes before committing!

---

## 📏 Best Practices

### DO ✅
```dart
// Use appropriate log level
Logger.d('Debug info');        // Development only
Logger.i('Important event');   // Notable events
Logger.w('Warning');           // Potential issues
Logger.e('Error', error: e);   // Actual errors

// Use tags for organization
Logger.d('Message', tag: 'Payment');

// Include context in messages
Logger.i('Order #${orderId} submitted for ${amount} THB');

// Log errors with stack traces
Logger.e('Failed', error: e, stackTrace: s);
```

### DON'T ❌
```dart
// Don't use print() anymore
print('Debug message'); // ❌

// Don't wrap in kDebugMode manually
if (kDebugMode) {
  Logger.d('Message'); // ❌ Logger already checks kDebugMode
}

// Don't log sensitive data
Logger.d('Password: $password'); // ❌ Security issue!

// Don't log every tiny detail
Logger.d('Variable x = 5'); // ❌ Too verbose
```

---

## 🔒 Security Considerations

### Never log:
- ❌ Passwords
- ❌ Credit card numbers
- ❌ Personal identification numbers (PIN)
- ❌ API keys or tokens
- ❌ User's personal data (unless anonymized)

### Example:
```dart
// ❌ BAD
Logger.d('User password: $password');
Logger.d('Card number: $cardNumber');

// ✅ GOOD
Logger.d('User authenticated successfully');
Logger.d('Payment processed: ****${cardNumber.substring(12)}');
```

---

## 📈 Performance Impact

### Debug Mode:
- Logs are written to console
- Minimal performance impact
- Helps debugging

### Production Mode:
- **Zero logs** - all Logger calls are no-ops
- **Zero performance impact** - compiler strips out log strings
- **Smaller APK** - no log strings included in build

### Verification:
```bash
# Build release APK
flutter build apk --release

# Decompile and search for log strings
# You should find ZERO log messages!
```

---

## 🧪 Testing

### Verify logs work:
```bash
# Run in debug mode
flutter run

# You should see logs in console
# [DeDe Kiosk][...] messages
```

### Verify logs don't appear in production:
```bash
# Build release
flutter build apk --release --dart-define=ENVIRONMENT=PROD

# Install and run
# No logs should appear in logcat
adb logcat | grep "DeDe Kiosk"
# Should show nothing!
```

---

## 📞 FAQ

**Q: Will logs appear in production?**
A: No! `kDebugMode` is false in release builds, so all Logger calls are skipped.

**Q: Does this slow down production?**
A: No! The Dart compiler completely removes Logger calls in release mode.

**Q: Can I still use print()?**
A: You can, but shouldn't. Logger is better and production-safe.

**Q: How do I filter logs?**
A: Use tags and grep: `flutter run | grep "\[Payment\]"`

**Q: What about existing print() statements?**
A: Migrate them gradually or use the `replace_prints.py` script.

---

## ✨ Summary

### Old Way:
```dart
if (kDebugMode) {
  print('Debug message');
  print('Error: $e');
  print('Stack: $s');
}
```

### New Way:
```dart
Logger.d('Debug message');
Logger.e('Error occurred', error: e, stackTrace: s);
```

**Result:** Cleaner code, better organization, production-safe! 🎉

---

**Start using Logger today for better debugging and safer production builds!**
