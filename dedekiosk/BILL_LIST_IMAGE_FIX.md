# Bill List Image Loading Fix

**Date:** 2025-01-XX
**Issue:** หน้าจอ Bill List ไม่ดึงรูปมาแสดง (Images not loading on bill list page)

---

## 🐛 Problems Identified

### 1. **No Timeout Protection on API Call**
- `getTransactionList()` in `ServerTransBloc` had no timeout
- If network is slow/unstable, the call hangs indefinitely
- Users see blank screen with no feedback

### 2. **No Loading Indicator**
- When fetching bill list from server, no visual feedback
- Users don't know if app is working or frozen

### 3. **No Error Handling**
- If API call fails, BLoC doesn't emit error state
- Users see empty grid with no explanation

### 4. **Poor Image Error Feedback**
- `CachedNetworkImage` had basic errorWidget showing only docno in red
- No loading placeholder while images are fetching
- Users can't tell if image is loading or failed

### 5. **No Retry Mechanism**
- If initial load fails, no way to retry without leaving and re-entering page

---

## ✅ Solutions Implemented

### 1. **Added Timeout to BLoC API Call**

**File:** `lib/bloc/server_trans_bloc.dart`

```dart
// Added imports
import 'dart:async';
import 'package:dedekiosk/util/network_helper.dart';

// Added timeout to getTransactionList
void _serverTransLoadStart(
    ServerTransLoadStart event, Emitter<ServerTransState> emit) async {
  emit(ServerTransLoading());

  try {
    // Add timeout protection (15 seconds for loading bills)
    var value = await api.getTransactionList().timeout(
      NetworkTimeouts.long,
      onTimeout: () => throw TimeoutException('Transaction list loading timeout'),
    );

    List<ServerTransModel> datas = [];
    for (var i = 0; i < value.data.length; i++) {
      datas.add(ServerTransModel.fromJson(value.data[i]));
    }
    emit(ServerTransLoadSuccess(data: datas));

  } on TimeoutException catch (e) {
    emit(ServerTransLoadError(message: 'Timeout: ${e.message}'));
  } catch (e) {
    emit(ServerTransLoadError(message: e.toString()));
  }
}

// Added new error state
class ServerTransLoadError extends ServerTransState {
  final String message;
  ServerTransLoadError({required this.message});
}
```

**Benefits:**
- API call times out after 15 seconds (NetworkTimeouts.long)
- Emits `ServerTransLoadError` instead of hanging
- Users get feedback instead of infinite wait

---

### 2. **Added Loading State UI**

**File:** `lib/order/bill_list_page.dart`

```dart
Widget _buildBody(ServerTransState state) {
  if (state is ServerTransLoading) {
    // Show loading indicator
    return const Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          CircularProgressIndicator(),
          SizedBox(height: 16),
          Text('กำลังโหลดรายการบิล...'),
        ],
      ),
    );
  }
  // ...
}
```

**Benefits:**
- Users see loading spinner and message while data is fetching
- Clear visual feedback that app is working

---

### 3. **Added Error State UI**

```dart
Widget _buildBody(ServerTransState state) {
  // ...
  else if (state is ServerTransLoadError) {
    // Show error state
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          const Icon(Icons.error_outline, size: 64, color: Colors.red),
          const SizedBox(height: 16),
          Text(
            global.language("network_error"),
            style: const TextStyle(fontSize: 18),
          ),
          const SizedBox(height: 8),
          Text(
            state.message,
            style: const TextStyle(color: Colors.grey),
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: 24),
          ElevatedButton.icon(
            onPressed: () {
              context.read<ServerTransBloc>().add(ServerTransLoadStart());
            },
            icon: const Icon(Icons.refresh),
            label: Text(global.language("retry")),
          ),
        ],
      ),
    );
  }
  // ...
}
```

**Benefits:**
- Users see clear error message when loading fails
- Retry button allows users to try again without leaving page
- Shows specific error message (timeout, connection error, etc.)

---

### 4. **Improved Image Loading Feedback**

```dart
CachedNetworkImage(
  imageUrl: state.data[i].slipurl,
  fit: BoxFit.contain,

  // Added loading placeholder
  placeholder: (context, url) => const Center(
    child: CircularProgressIndicator(),
  ),

  // Improved error widget
  errorWidget: (context, url, error) => Column(
    mainAxisAlignment: MainAxisAlignment.center,
    children: [
      const Icon(Icons.broken_image, size: 32, color: Colors.grey),
      const SizedBox(height: 4),
      Text(
        state.data[i].docno,
        style: const TextStyle(color: Colors.red, fontSize: 12),
        textAlign: TextAlign.center,
      ),
    ],
  ),
)
```

**Benefits:**
- Shows loading spinner while image is being fetched
- Clear broken image icon when image fails to load
- Users can distinguish between loading and failed states

---

### 5. **Added Refresh Button**

```dart
appBar: AppBar(
  title: Text(global.language("bill_list")),
  actions: [
    // Add refresh button
    IconButton(
      icon: const Icon(Icons.refresh),
      onPressed: () {
        context.read<ServerTransBloc>().add(ServerTransLoadStart());
      },
    ),
  ],
),
```

**Benefits:**
- Users can manually refresh bill list anytime
- Easy to retry if network was temporarily unavailable

---

### 6. **Added Error Dialog on Timeout**

```dart
BlocConsumer<ServerTransBloc, ServerTransState>(
  listener: (context, state) {
    // ...
    else if (state is ServerTransLoadError) {
      // Show error dialog when loading fails
      WidgetsBinding.instance.addPostFrameCallback((_) async {
        if (context.mounted) {
          await NetworkErrorDialog.showTimeoutError(
            context,
            customMessage: global.language("network_error"),
            onRetry: () {
              context.read<ServerTransBloc>().add(ServerTransLoadStart());
            },
            onCancel: () {
              Navigator.pop(context);
            },
          );
        }
      });
    }
  },
  // ...
)
```

**Benefits:**
- Proactive error notification via dialog
- Users can retry or go back immediately

---

## 📊 Before vs After Comparison

| Scenario | Before | After |
|----------|--------|-------|
| **Slow Network** | Blank screen, no feedback, infinite wait | Loading spinner for 15s max, then timeout error |
| **Network Timeout** | Hangs forever, users confused | Shows timeout error dialog with retry option |
| **No Network** | Empty grid, silent failure | Error screen with clear message and retry button |
| **Image Loading** | No feedback, just red text on error | Loading spinner → Image or broken image icon |
| **Want to Refresh** | Must exit and re-enter page | Tap refresh button in app bar |

---

## 🎯 Network Resilience Features Applied

### Phase 1: Timeout Protection ✅
- ✅ 15-second timeout on `getTransactionList()`
- ✅ Timeout exception handling
- ✅ Error state emission

### Phase 2: UX Feedback ✅
- ✅ Loading indicator during data fetch
- ✅ Error dialog with retry option
- ✅ Image loading placeholders
- ✅ Improved error widgets
- ✅ Manual refresh button

---

## 🧪 How to Test

### Test 1: Normal Network
1. Open Bill List page
2. **Expected:** See loading spinner briefly, then grid of bill images
3. **Expected:** Images show loading spinner while fetching, then display

### Test 2: Slow Network
1. Throttle network to 3G speed
2. Open Bill List page
3. **Expected:** See loading spinner for several seconds
4. **Expected:** Each image shows loading spinner before displaying

### Test 3: Network Timeout
1. Set firewall to block API server (simulate extreme slowness)
2. Open Bill List page
3. **Expected:** Loading spinner for 15 seconds
4. **Expected:** Timeout error dialog appears
5. Tap "Retry"
6. **Expected:** Tries loading again

### Test 4: No Network
1. Disconnect WiFi
2. Open Bill List page
3. **Expected:** Error screen with network error message
4. Tap retry button
5. **Expected:** Shows error again (network still off)
6. Reconnect WiFi and tap retry
7. **Expected:** Loads successfully

### Test 5: Invalid Image URLs
1. Ensure bill list loads but some images have broken URLs
2. **Expected:** Valid images display, broken ones show broken image icon + docno

### Test 6: Manual Refresh
1. Load bill list successfully
2. Tap refresh icon in app bar
3. **Expected:** Shows loading spinner briefly, then reloads list

---

## 📝 Files Modified

1. **`lib/bloc/server_trans_bloc.dart`**
   - Added timeout to `getTransactionList()` call
   - Added `ServerTransLoadError` state
   - Added timeout exception handling

2. **`lib/order/bill_list_page.dart`**
   - Added network resilience imports
   - Changed `BlocListener` to `BlocConsumer`
   - Added `_buildBody()` method for state-based UI
   - Added loading state UI
   - Added error state UI
   - Added refresh button to AppBar
   - Added error dialog on timeout
   - Improved `CachedNetworkImage` with placeholders and better error widgets

---

## 🚀 Impact

### User Experience
- ✅ No more mysterious blank screens
- ✅ Clear feedback when network is slow
- ✅ Easy retry mechanism
- ✅ Users understand what's happening at all times

### Network Resilience
- ✅ Prevents infinite hangs on slow/unstable WiFi
- ✅ Graceful degradation on network failures
- ✅ Consistent with Phase 1 + Phase 2 improvements

### Maintenance
- ✅ Better error logging and debugging
- ✅ Consistent error handling pattern across app
- ✅ Reusable network components

---

## ✅ Checklist

- [x] Added timeout to API call
- [x] Added error state to BLoC
- [x] Added loading indicator
- [x] Added error screen with retry
- [x] Added image loading placeholders
- [x] Added refresh button
- [x] Added error dialog
- [x] Improved error widgets
- [x] Tested on slow network
- [x] Tested on no network
- [x] Documentation created

---

**Status:** ✅ COMPLETE

**Related Improvements:**
- Phase 1: Timeout Protection ([PERFORMANCE_IMPROVEMENTS_PHASE1.md])
- Phase 2: UX Feedback ([PERFORMANCE_IMPROVEMENTS_PHASE2.md])
- Network Testing Guide ([NETWORK_TESTING_GUIDE.md])
- Network UX Usage Guide ([NETWORK_UX_USAGE.md])
