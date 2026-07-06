# Testing Guide - DeDe Kiosk Performance Improvements

**Version:** 1.0
**Date:** 2025-01-XX
**Target:** Phase 1 + Phase 2 Optimizations

---

## 📋 Quick Start

### For Windows:
```bash
# Run automated test script
test_performance.bat
```

### For Linux/Mac:
```bash
# Make script executable
chmod +x test_performance.sh

# Run automated test script
./test_performance.sh
```

---

## 🎯 Testing Strategy

### Stage 1: Automated Tests (10 minutes)
Run the test script to verify code quality and gather basic metrics.

### Stage 2: Manual Performance Tests (20 minutes)
Use Flutter DevTools to verify performance improvements.

### Stage 3: Functional Regression Tests (30 minutes)
Verify all features work correctly after changes.

### Stage 4: Real-World Testing (1-2 hours)
Test in production-like environment with actual use cases.

---

## 🔧 Setup Instructions

### 1. Install Flutter DevTools

```bash
# Install DevTools globally
flutter pub global activate devtools

# Run DevTools
flutter pub global run devtools
```

### 2. Build App in Profile Mode

```bash
# For Android
flutter run --profile

# For Windows
flutter run --profile -d windows

# For iOS
flutter run --profile -d ios
```

**Important:** Always use `--profile` mode for performance testing, NOT debug mode!

---

## 📊 Test Cases

### Test 1: Startup Time ⏱️

**Objective:** Verify app starts 50-60% faster

**Steps:**
1. Close app completely (kill from task manager)
2. Clear app cache (optional but recommended)
3. Launch app with stopwatch
4. Stop when first interactive frame appears

**Expected Results:**
- **Before:** 3-5 seconds
- **After:** 1-2 seconds
- **Pass Criteria:** <2.5 seconds

**How to Measure:**
```bash
# Method 1: Using Flutter
flutter run --profile --trace-startup

# Method 2: Visual timing
# Use stopwatch from app icon tap to first screen visible
```

---

### Test 2: Memory Usage 💾

**Objective:** Verify memory usage reduced by 21%

**Steps:**
1. Open DevTools Memory tab
2. Launch app
3. Wait for initial load (30 seconds)
4. Take memory snapshot
5. Note RSS (Resident Set Size)

**Expected Results:**
- **Before:** ~280MB
- **After:** ~220MB
- **Pass Criteria:** <240MB

**How to Measure:**
```bash
# In DevTools:
# 1. Memory tab
# 2. Look for "Current" value
# 3. Should see ~220MB after startup
```

**Screenshot Location:** Take screenshot and save to `test_results/memory_initial.png`

---

### Test 3: Memory Leak Test 🔍

**Objective:** Verify 100% memory leak fixes

**Steps:**
1. Take initial memory snapshot in DevTools
2. Perform these actions 20 times:
   - Open payment credit card page
   - Enter card info
   - Cancel payment
   - Go back
3. Take final memory snapshot
4. Compare TextEditingController counts

**Expected Results:**
- **TextEditingController count:** No increase
- **StreamSubscription count:** No increase
- **Memory growth:** <5MB

**Pass Criteria:**
- Zero TextEditingController leaks
- Zero StreamSubscription leaks
- Memory stable or minimal growth

---

### Test 4: BLoC Lazy Loading 🚀

**Objective:** Verify 82% reduction in initial BLoC loading

**Steps:**
1. Restart app in profile mode
2. Open DevTools → Provider tab (or Widget Inspector)
3. Count BLoC instances at startup
4. Navigate to KDS screen
5. Verify new BLoC created

**Expected Results:**
- **At startup:** 2 BLoCs (CategoryBloc, OrderTempBloc)
- **After KDS:** 3 BLoCs (+ ClickHouseOrderTempKdsBloc)
- **Pass Criteria:** ≤3 BLoCs at startup

---

### Test 5: Image Caching 🖼️

**Objective:** Verify 90% faster image loading on repeat

**Steps:**
1. Clear app cache completely
2. Open order screen
3. Scroll through products (measure load time)
4. Go back to main menu
5. Return to order screen
6. Scroll to same products (measure load time)

**Expected Results:**
- **First load:** 500-1000ms per image (network)
- **Second load:** <100ms per image (cached)
- **Pass Criteria:** <100ms on repeat

**How to Measure:**
```bash
# Use DevTools Network tab
# Look for cached image indicators
# Or use stopwatch visual method
```

---

### Test 6: CPU Usage 🔋

**Objective:** Verify 40-50% CPU reduction on idle

**Steps:**
1. Launch app
2. Go to main screen (idle)
3. Open Task Manager (Windows) or Activity Monitor (Mac)
4. Monitor CPU usage for 60 seconds
5. Calculate average

**Expected Results:**
- **Before (Client):** 15-20%
- **After (Client):** 8-12%
- **Before (Server):** 25-30%
- **After (Server):** 18-22%

**Pass Criteria:**
- Client: <13%
- Server: <23%

---

### Test 7: Functional Regression 🧪

**Objective:** Verify no functionality broken

#### 7.1 Order Flow
- [ ] Select products from multiple categories
- [ ] Add products with options
- [ ] Modify cart quantities
- [ ] Complete order

#### 7.2 Payment Flow
- [ ] Cash payment
- [ ] Credit card (EDC) - **Critical: Tests controller disposal**
- [ ] QR payment (2+ gateways)
- [ ] Payment calculation accuracy

#### 7.3 Printing
- [ ] Receipt printing
- [ ] Kitchen order printing
- [ ] Printer configuration - **Critical: Tests controller disposal**

#### 7.4 Special Features
- [ ] KDS screen - **Critical: Tests lazy BLoC loading**
- [ ] Table management - **Critical: Tests lazy BLoC loading**
- [ ] Member system
- [ ] Multi-language switching

#### 7.5 Background Operations
- [ ] Order sync (5 second timer)
- [ ] Payment sync (2 second timer, server only)
- [ ] Print queue processing
- [ ] Device registration

---

## 🐛 Debugging Failed Tests

### If Startup Time > 2.5s:
```dart
// Check if Phase 2 lazy loading is working
// In main.dart, verify lazy: true for most BLoCs

// Debug:
flutter run --profile --trace-startup
// Look for slow operations in trace
```

### If Memory > 240MB:
```dart
// Check for memory leaks
// In DevTools, take snapshot and look for:
// - TextEditingController accumulation
// - StreamSubscription accumulation
// - Large image caches

// Debug:
// Use Memory Profiler in DevTools
// Look for "Top Consumers"
```

### If BLoCs > 3 at Startup:
```dart
// Check main.dart BLoC providers
// Ensure lazy: true for non-essential BLoCs

// Debug:
// Add print statements in BLoC constructors
debugPrint('BLoC created: ${this.runtimeType}');
```

### If Images Don't Cache:
```dart
// Check CachedNetworkImage implementation
// Verify memCacheWidth/Height set

// Debug:
// Check DevTools Network tab
// Should see "from cache" for repeat loads

// Clear cache and retry:
await CachedNetworkImage.evictFromCache(imageUrl);
```

---

## 📈 Performance Monitoring (Real-Time)

### Option 1: Use Built-in Monitor Widget

```dart
// In main.dart, wrap your app:
import 'monitor_performance.dart';

runApp(
  PerformanceMonitor(
    enabled: true, // Set to false in production
    child: MyApp(),
  ),
);

// Tap the analytics icon to view real-time metrics
// Export metrics to analyze performance
```

### Option 2: Use Flutter DevTools

```bash
# Launch DevTools
flutter pub global run devtools

# Connect to running app
# View Performance tab for:
# - Frame rendering time
# - Rebuild counts
# - Memory allocations
```

---

## 📊 Expected Test Results Summary

| Test | Metric | Before | Target | Pass If |
|------|--------|--------|--------|---------|
| Startup Time | Time to first frame | 3-5s | 1-2s | <2.5s |
| Initial Memory | RSS | 280MB | 220MB | <240MB |
| Memory Leaks | Controller count | Growing | Stable | No growth |
| BLoC Count | At startup | 11 | 2 | ≤3 |
| Image Cache | Repeat load | 500-1000ms | <100ms | <100ms |
| CPU (Client) | Idle usage | 15-20% | 8-12% | <13% |
| CPU (Server) | Idle usage | 25-30% | 18-22% | <23% |

---

## ✅ Pass/Fail Criteria

### Phase 1 (Low Risk) - Must Pass All
- ✅ Memory leaks: ZERO
- ✅ Functional tests: 100% pass
- ✅ CPU usage: At least 30% reduction

### Phase 2 (Medium Risk) - Must Pass 80%
- ✅ Startup time: <2.5s
- ✅ BLoC count: ≤3
- ✅ Image caching: Working
- ⚠️ May have minor issues but overall good

---

## 🚀 Deployment Decision Matrix

| Test Results | Decision |
|--------------|----------|
| All Phase 1 + Phase 2 Pass | ✅ Deploy Both Immediately |
| All Phase 1 Pass, Phase 2 80%+ | ✅ Deploy Phase 1, Monitor Phase 2 |
| Phase 1 Pass, Phase 2 <80% | ⚠️ Deploy Phase 1 Only |
| Phase 1 Fails | ❌ Fix Issues, Retest |

---

## 📝 Test Report Template

```markdown
# Performance Test Report

**Date:** ___________
**Tester:** ___________
**Device:** ___________
**Build:** ___________

## Results

### Phase 1 Tests
- Memory Leaks: ✅/❌
- Controller Disposal: ✅/❌
- Timer Optimization: ✅/❌

### Phase 2 Tests
- Startup Time: ___s (✅/❌)
- BLoC Loading: ___ BLoCs (✅/❌)
- Image Cache: ✅/❌

### Functional Tests
- Order Flow: ✅/❌
- Payment: ✅/❌
- Printing: ✅/❌
- KDS: ✅/❌

## Decision
[ ] Approved for Deployment
[ ] Needs Fixes

## Notes
___________________________
```

---

## 🆘 Support

### If Tests Fail:
1. Check [DEPLOYMENT_CHECKLIST.md](DEPLOYMENT_CHECKLIST.md)
2. Review Phase 1/Phase 2 implementation
3. Verify all files were updated correctly
4. Check for merge conflicts

### Performance Issues:
1. Use DevTools Performance tab
2. Check for widget rebuild storms
3. Verify timers are optimized
4. Look for memory leaks

### Questions:
- Refer to PERFORMANCE_IMPROVEMENTS_PHASE1.md
- Refer to PERFORMANCE_IMPROVEMENTS_PHASE2.md

---

**Remember:** Test in profile mode, not debug mode!

**Good luck with testing!** 🚀
