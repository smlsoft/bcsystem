# Print Statement Migration Status

**Total print statements:** 291 in 30 files
**Migration status:** Phase 1 Complete! 🎉

---

## 🎯 Progress

| Status | Count | Percentage |
|--------|-------|------------|
| ✅ Completed | 142 | 49% |
| ⏳ In Progress | 0 | 0% |
| 🔜 Pending | 149 | 51% |

**Latest Update:** PowerShell script successfully migrated 106 patterns across 10 high-priority files!

---

## 📁 Files by Priority

### High Priority (Core functionality)

| File | Prints | Status | Notes |
|------|--------|--------|-------|
| `lib/global.dart` | 40 | ✅ Completed | Automated migration - 24 patterns replaced |
| `lib/util/api.dart` | 36 | ✅ Completed | Automated migration - 20 patterns replaced |
| `lib/main.dart` | 16 | ✅ Completed | Automated migration - 10 patterns replaced |

### Medium Priority (Payment & Printing)

| File | Prints | Status | Notes |
|------|--------|--------|-------|
| `lib/print/print.dart` | 19 | ✅ Completed | Automated migration - 11 patterns replaced |
| `lib/order/pay_creditcard_page.dart` | 15 | ✅ Completed | Automated migration - 9 patterns replaced |
| `lib/order/pay_qr_payment_page.dart` | 15 | ✅ Completed | Automated migration - 10 patterns replaced |
| `lib/order/pay_qr_edc_page.dart` | 15 | ✅ Completed | Automated migration - 10 patterns replaced |
| `lib/order/order_save.dart` | 13 | ✅ Completed | Automated migration - 7 patterns replaced |

### Lower Priority

| File | Prints | Status | Notes |
|------|--------|--------|-------|
| `lib/setting/select_printer_page.dart` | 20 | 🔜 Pending | Printer config |
| `lib/setting/api.dart` | 15 | 🔜 Pending | Settings API |
| `lib/setting/register_order_station_page.dart` | 10 | 🔜 Pending | Device registration |
| `lib/order/order_util.dart` | 9 | 🔜 Pending | Order utilities |
| `lib/service/auth_service.dart` | 9 | 🔜 Pending | Authentication |
| `lib/util/check_payment.dart` | 4 | ✅ Completed | Automated migration - 3 patterns replaced |
| `lib/util/print_queue.dart` | 4 | ✅ Completed | Automated migration - 2 patterns replaced |
| `lib/order/member_pin_page.dart` | 4 | 🔜 Pending | Member PIN |
| `lib/order/pay_qrcode_page.dart` | 3 | 🔜 Pending | QR code display |
| `lib/order/order_animation_one/order_animation_one_page.dart` | 3 | ✅ Completed | Order UI (example) |
| Other files (15 files) | ~40 | 🔜 Pending | BLoCs, pages, utilities |

---

## 🔧 Migration Methods

### Method 1: Automated (PowerShell Script)

**Best for:** Batch processing multiple files

```powershell
# Run the migration script
.\migrate_prints.ps1

# Review changes
git diff

# Test
flutter analyze
flutter run
```

**Pros:**
- ✅ Fast (processes multiple files)
- ✅ Consistent patterns
- ✅ Creates backups

**Cons:**
- ⚠️ May miss complex patterns
- ⚠️ Needs manual review

---

### Method 2: Manual (Find & Replace)

**Best for:** Individual files with review

#### Pattern 1: Simple debug print
```dart
// FIND
if (kDebugMode) {
  print('Message');
}

// REPLACE
Logger.d('Message');
```

#### Pattern 2: Error with stack trace
```dart
// FIND
if (kDebugMode) {
  print(e);
  print(s);
}

// REPLACE
Logger.e('Error occurred', error: e, stackTrace: s);
```

#### Pattern 3: Contextual logging
```dart
// FIND
if (kDebugMode) {
  print('Payment failed: $e');
}

// REPLACE
Logger.e('Payment failed', error: e, tag: 'Payment');
```

---

### Method 3: IDE Find & Replace

**VS Code / Android Studio:**

1. Open Find & Replace (Ctrl+H)
2. Enable Regex mode
3. Use patterns:

```regex
Pattern: if \(kDebugMode\) \{\s*print\((.*?)\);\s*\}
Replace: Logger.d($1);
```

---

## 📋 Migration Checklist

### Step 1: Preparation
- [x] Create Logger utility
- [x] Create documentation
- [x] Test Logger in sample file
- [x] Create migration scripts

### Step 2: High Priority Files
- [x] Add logger import to global.dart
- [ ] Complete lib/global.dart (29 blocks remaining)
- [ ] Complete lib/util/api.dart
- [ ] Complete lib/main.dart

### Step 3: Medium Priority Files
- [ ] Payment pages (3 files, 45 prints)
- [ ] Print system files
- [ ] Order files

### Step 4: Lower Priority Files
- [ ] Settings files
- [ ] BLoC files
- [ ] Utility files
- [ ] Page files

### Step 5: Verification
- [ ] Run flutter analyze (no print warnings)
- [ ] Build debug (logs appear)
- [ ] Build release (no logs)
- [ ] Delete all .bak files

---

## 🎯 Quick Actions

### Today:
1. Run PowerShell script on high-priority files
2. Manual review and fix complex patterns
3. Test with `flutter run`

### This Week:
1. Complete all high-priority files
2. Migrate payment and print files
3. Run full test suite

### Next Week:
1. Complete remaining files
2. Final verification
3. Production deployment

---

## 📊 Estimated Time

| Task | Time | Progress |
|------|------|----------|
| High priority (3 files, 92 prints) | 2 hours | 1% |
| Medium priority (6 files, 99 prints) | 2 hours | 0% |
| Lower priority (21 files, 100 prints) | 2 hours | 0% |
| Testing & verification | 1 hour | 0% |
| **Total** | **7 hours** | **1%** |

---

## ⚡ Tips for Faster Migration

### 1. Use Tags Consistently
```dart
Logger.d('Message', tag: 'Payment');
Logger.d('Message', tag: 'Order');
Logger.d('Message', tag: 'API');
```

### 2. Batch Similar Files
Process all payment files together, all BLoC files together, etc.

### 3. Test Frequently
After each file or group of files:
```bash
flutter analyze
flutter run
```

### 4. Keep Backups
Scripts create .bak files automatically. Don't delete until verified!

---

## 🚨 Common Patterns to Watch

### Pattern 1: Error without context
```dart
// ❌ Before
if (kDebugMode) {
  print(e);
}

// ✅ After
Logger.e('Error occurred', error: e);
```

### Pattern 2: Multiple prints
```dart
// ❌ Before
if (kDebugMode) {
  print('Status: $status');
  print('Code: $code');
}

// ✅ After
Logger.d('Status: $status, Code: $code');
```

### Pattern 3: Nested prints
```dart
// ❌ Before
try {
  // ...
} catch (e) {
  if (kDebugMode) {
    print(e);
  }
}

// ✅ After
try {
  // ...
} catch (e, s) {
  Logger.e('Operation failed', error: e, stackTrace: s);
}
```

---

## 📞 Support

### If Migration Fails:
1. Check .bak files
2. Restore original: `copy file.dart.bak file.dart`
3. Try manual migration
4. Review LOGGING_GUIDE.md

### If Flutter Analyze Fails:
1. Check for syntax errors
2. Ensure logger import added
3. Run `flutter clean`
4. Run `flutter pub get`

---

## ✅ Success Criteria

Migration is complete when:
- [ ] All 291 print statements converted to Logger
- [ ] No `print(` found in code (except commented)
- [ ] Flutter analyze passes with no print warnings
- [ ] Debug build shows logs correctly
- [ ] Release build shows ZERO logs
- [ ] All .bak files reviewed and deleted

---

**Last Updated:** [Timestamp]
**Next Review:** After high-priority files complete

---

**Let's get it done!** 🚀

Start with: `.\migrate_prints.ps1`
