# AGENTS.md

This file provides guidance to Codex (Codex.ai/code) when working with code in this repository.

## Project Overview

**DeDe Kiosk** is a Flutter-based self-service kiosk and order station application for restaurants. It supports multiple platforms (Android, iOS, Windows, Web) and integrates with various payment gateways, thermal printers, and the DeDe POS backend system.

### Key Features
- Multi-language kiosk ordering interface (Thai, English, Lao, Chinese, Japanese, Korean)
- Multiple payment gateway integrations (TigerBoard, LugentPay, PromptPay, GBPrimePay, Xendit)
- Thermal printer support for receipts and kitchen orders
- Real-time order synchronization with backend
- Kitchen Display System (KDS) and served order views
- Member/loyalty program integration
- Firebase authentication (Google Sign-In, Apple Sign-In)
- ObjectBox local database for offline order management

## Development Commands

### Code Generation
```bash
# Generate code for json_serializable, freezed, and ObjectBox
flutter pub run build_runner build --delete-conflicting-outputs
```

### Running the App
```bash
# Development mode (uses DEV environment)
flutter run

# Production mode
flutter run --release --dart-define=ENVIRONMENT=PROD

# Staging mode
flutter run --release --dart-define=ENVIRONMENT=STAGING
```

### Building

#### Android
```bash
# Debug APK
flutter build apk

# Release APK (production)
flutter build apk --release --dart-define=ENVIRONMENT=PROD

# App Bundle (for Play Store)
flutter build appbundle --release --dart-define=ENVIRONMENT=PROD

# Build and upload APK (uses xbuild.sh script)
./xbuild.sh

# Build and upload using Python script
python .\apkupload.py
```

#### iOS
```bash
flutter build ipa --release --dart-define=ENVIRONMENT=PROD
```

#### Windows
```bash
# Build Windows app
flutter build windows

# Create MSIX installer
flutter pub run msix:create --build-windows false --os-min-version 10.0.17134.83

# Build and upload
python .\windowsupload.py
```

### Testing
```bash
# Run tests
flutter test
```

### Linting
```bash
# Analyze code
flutter analyze
```

## Architecture

### State Management
- **BLoC Pattern**: Primary state management using `flutter_bloc`
- **GetX**: Used for navigation and route management
- **Global State**: `lib/global.dart` contains app-wide state and utility functions

### Key BLoCs
- `CategoryBloc` - Product category management
- `OrderTempBloc` - Local order management (ObjectBox)
- `ClickHouseOrderTempBloc` - Server-side order state
- `ClickHouseOrderTempKdsBloc` - Kitchen display orders
- `ClickHouseOrderTempServedBloc` - Served order tracking
- `ClickHouseOrderTempTableBloc` - Table order management
- `ServerTransBloc` - Transaction synchronization
- `LoginBloc` - Authentication
- `ListShopBloc` - Shop selection
- `ShopSelectBloc` - Selected shop management
- `ListKioskBloc` - Kiosk device management

### Directory Structure

```
lib/
├── app/              # App-level constants
├── bloc/             # BLoC state management
├── edckbank/         # EDC payment terminal integration
├── model/            # Data models (with json_serializable/freezed)
├── objectbox/        # Local database models and generated code
├── order/            # Order-related pages and logic
│   ├── order_animation_one/  # Animated order UI variant
│   └── order_standard/       # Standard order UI
├── page/             # Main application pages
├── print/            # Thermal printer integration
├── service/          # Repository and service layer
├── setting/          # Settings and device configuration
├── util/             # Utilities and helpers
└── widget/           # Reusable widgets
```

### Environment Configuration

The app uses compile-time environment variables:

```dart
// Set via --dart-define=ENVIRONMENT=<env>
// Values: DEV, STAGING, PROD
// Default: DEV
```

**API Endpoints** (configured in `lib/app/app_constant.dart`):
- **PROD**: `https://api.dedepos.com`
- **DEV**: `https://api.dev.dedepos.com`
- **STAGING**: `https://api.uat.dedepos.com/v2`

Environment is initialized in `main.dart` via `Environment().initConfig(environment)`

### Data Flow

1. **Local Orders**: Stored in ObjectBox (`OrderTempObjectBoxModel`)
2. **Server Sync**: Background timers sync orders to ClickHouse database
3. **Payment Flow**:
   - QR payment requests → Payment gateway packages
   - Payment polling via `checkPaymentOnline()` (runs every 1 second)
4. **Printing**: Queue-based system via `printQueueWorker()` (runs every 1 second)

### Background Workers (main.dart)

Critical background timers initialized in `main()`:
- **Every 20 seconds**: Device registration (`registerDeviceToServer()`)
- **Every 1 second**: Print queue processing (`printQueueWorker()`)
- **Every 5 seconds**: Order sync and slip upload (`checkOrderOnline()`, `uploadSlipWorker()`)
- **Every 1 second**: Payment status checking (`checkPaymentOnline()`)

### Custom Packages

Located in `packages/`:
- **lugentpay**: LugentPay payment gateway integration (Thai QR, LINE Pay, Alipay, WeChat Pay, TrueMoney, BCEL OnePay)
- **promptpay**: PromptPay QR code generation and payment
- **gbprimepay**: GBPrimePay payment gateway
- **xenditpay**: Xendit payment gateway
- **smlkapi**: SML K-Bank connector for QR payments (PromptPay and credit card)
- **tigerboard**: TigerBoard payment gateway integration

### Payment Integration Pattern

All payment packages follow similar structure:
1. Generate QR/payment request
2. Poll for payment status via inquiry endpoint
3. Cancel payment if needed

Example workflow:
```dart
// Generate payment
var response = await paymentGateway.generatePayment(amount, ref);

// Poll for status
Timer.periodic(Duration(seconds: 2), (timer) async {
  var status = await paymentGateway.inquiryPayment(response.id);
  if (status.isPaid) {
    timer.cancel();
    // Process successful payment
  }
});
```

### Print System

Three-tier printing architecture:
- `print_queue.dart`: Queue management and worker
- `print_process.dart`: High-level print coordination
- `print.dart`: Receipt printing
- `print_kitchen.dart`: Kitchen order printing
- `print_util.dart`: Print formatting utilities

Printer configuration stored in `global.deviceConfig.printerList`

## Important Global State (lib/global.dart)

Key global variables and functions:
- `deviceConfig`: Device settings (shop ID, kiosk name, printer config, etc.)
- `shopProfile`: Current shop information
- `languageSystemData`: Multi-language strings
- `categoryList`: Product categories
- `productList`: Available products
- `objectBoxStore`: Local database instance
- `printQueue`: Print job queue
- `orderId`: Current order ID

**Critical functions**:
- `loadConfig()`: Load device configuration from SharedPreferences
- `saveDeviceConfigToStorage()`: Persist device settings
- `registerDeviceToServer()`: Register/heartbeat to backend
- `languageSelect()`: Switch UI language
- `language(key)`: Get localized string

## Device Configuration

Device setup flow:
1. First launch → `/setting_main` (SettingMainDevicePage)
2. Register device → `/register_pos` (RegisterOrderStationPage)
3. Configure shop, kiosk, printers
4. Save to SharedPreferences (`order-station-device-config`)
5. Navigate to `/` (MainPage)

## Routing

Routes defined in `main.dart`:
- `/` - MainPage (home/dashboard)
- `/order` - OrderStandardPage (standard order UI)
- `/order_animation_one` - OrderAnimationOnePage (animated order UI)
- `/member_pin` - MemberPinPage (member PIN entry)
- `/select_member` - SelectMemberScreen (member type selection)
- `/order_select` - OrderSelectPage (order mode selection)
- `/setting` - SettingPage (kiosk settings)
- `/setting_main` - SettingMainDevicePage (device configuration)
- `/register_pos` - RegisterOrderStationPage (device registration)
- `/bill_list` - BillListPage (order history)
- `/order_served_by_waiter` - OrderServedPage (served orders view)
- `/kds` - OrderKdsPage (kitchen display system)

## Performance Considerations

**Critical performance patterns** (see PERFORMANCE_OPTIMIZATION_REPORT.md):

1. **TextEditingController Management**:
   - Always initialize controllers in `initState()`
   - Never create controllers in `build()` method
   - Always dispose in `dispose()` method

2. **Debounce Input Operations**:
   - Use debouncing (500ms) for text input that triggers saves
   - Avoid calling `saveDeviceConfigToStorage()` on every keystroke

3. **Minimize setState() Calls**:
   - Batch state updates when possible
   - Use debouncing to reduce rebuild frequency

4. **Widget Composition**:
   - Break large build methods into smaller widget methods
   - Extract repetitive UI patterns into reusable widgets

5. **Image Caching**:
   - Image cache limited to 3MB (set in `main.dart`)
   - Uses `cached_network_image` package

## Testing Credentials

Development test accounts in `lib/app/app_constant.dart`:
- User: `CHANGE_ME` / Password: `CHANGE_ME`
- Shop ID: `2OJMVIo1Qi81NqYos3oDPoASziy`

## Common Development Patterns

### Adding a New Payment Method

1. Create package in `packages/<payment_name>/`
2. Implement generate, inquiry, cancel methods
3. Add package to `pubspec.yaml` dependencies
4. Update payment selection UI in order pages
5. Add configuration in `global.deviceConfig`

### Adding a New Order UI Style

1. Create directory in `lib/order/order_<style_name>/`
2. Implement page, cart, and product option pages
3. Add route in `main.dart`
4. Update order selection page to include new style

### Modifying Device Configuration

1. Update `DeviceConfigModel` in `lib/model/global_model.dart`
2. Add UI fields in `lib/setting/setting_main_device_page.dart`
3. Use debounced save pattern for input fields
4. Ensure backwards compatibility with existing saved configs

## ObjectBox Database

ObjectBox is used for local order storage. Schema located in `lib/objectbox/`.

**Regenerate ObjectBox code** after schema changes:
```bash
flutter pub run build_runner build --delete-conflicting-outputs
```

Main entities:
- `OrderTempObjectBoxModel`: Local order items

## Firebase Configuration

Firebase configuration in `lib/firebase_options.dart` (auto-generated).

**Regenerate after Firebase changes**:
```bash
flutterfire configure
```

## Multi-language Support

Language files: `assets/language.json`

Language codes: `th`, `en`, `lo`, `cn`, `jp`, `kr`

Usage:
```dart
Text(global.language("key_name"))
```

## Build Scripts

- `xbuild.sh`: Build APK and upload to FTP server (Linux/Mac)
- `xbuilddev.sh`: Development build script
- `apkupload.py`: Build and upload APK (Windows)
- `windowsupload.py`: Build and upload Windows MSIX

## Version Management

Version defined in `pubspec.yaml`:
```yaml
version: 1.2.6+26  # format: <major>.<minor>.<patch>+<build_number>
```

Update both version string and build number when releasing.
