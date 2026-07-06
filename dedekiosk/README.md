# DeDe Kiosk

Flutter-based self-service kiosk and order station application for restaurants.

## Project Overview

**DeDe Kiosk** supports multiple platforms (Android, iOS, Windows, Web) and integrates with various payment gateways, thermal printers, and the DeDe POS backend system.

### Key Features
- Multi-language kiosk ordering interface (Thai, English, Lao, Chinese, Japanese, Korean)
- Multiple payment gateway integrations (TigerBoard, LugentPay, PromptPay, GBPrimePay, Xendit)
- Thermal printer support for receipts and kitchen orders
- Real-time order synchronization with backend
- Kitchen Display System (KDS) and served order views
- Member/loyalty program integration
- Firebase authentication (Google Sign-In, Apple Sign-In)

## Flavors

This project supports 2 flavors:

| Flavor | App Name | Package/Bundle ID |
|--------|----------|-------------------|
| **dedekiosk** | dedekiosk | com.smlsoft.dedekiosk |
| **bckiosk** | bckiosk | com.smlsoft.bckiosk |

## Prerequisites

- Flutter SDK 3.3.2 or higher
- Android Studio / Xcode (for mobile development)
- Visual Studio 2022 (for Windows development)

## Setup

### 1. Install Dependencies

```bash
flutter pub get
```

### 2. Generate Code

Generate code for json_serializable, freezed, and ObjectBox:

```bash
flutter pub run build_runner build --delete-conflicting-outputs
```

## Running the App

### Development Mode

#### dedekiosk flavor
```bash
# Run on connected device
flutter run --flavor dedekiosk --dart-define=ENVIRONMENT=DEV --dart-define=FLAVOR=dedekiosk

# Run on specific device
flutter run --flavor dedekiosk --dart-define=ENVIRONMENT=DEV --dart-define=FLAVOR=dedekiosk -d <device-id>
```

#### bckiosk flavor
```bash
# Run on connected device
flutter run --flavor bckiosk --dart-define=ENVIRONMENT=DEV --dart-define=FLAVOR=bckiosk

# Run on specific device
flutter run --flavor bckiosk --dart-define=ENVIRONMENT=DEV --dart-define=FLAVOR=bckiosk -d <device-id>
```

### Production/Release Mode

```bash
# dedekiosk
flutter run --release --flavor dedekiosk --dart-define=ENVIRONMENT=PROD --dart-define=FLAVOR=dedekiosk

# bckiosk
flutter run --release --flavor bckiosk --dart-define=ENVIRONMENT=PROD --dart-define=FLAVOR=bckiosk
```

## Building

### Android

#### Build APK (Debug)

```bash
# dedekiosk flavor
flutter build apk --flavor dedekiosk --dart-define=ENVIRONMENT=DEV --dart-define=FLAVOR=dedekiosk

# bckiosk flavor
flutter build apk --flavor bckiosk --dart-define=ENVIRONMENT=DEV --dart-define=FLAVOR=bckiosk
```

#### Build APK (Release - Production)

```bash
# dedekiosk flavor
flutter build apk --release --flavor dedekiosk --dart-define=ENVIRONMENT=PROD --dart-define=FLAVOR=dedekiosk

# bckiosk flavor
flutter build apk --release --flavor bckiosk --dart-define=ENVIRONMENT=PROD --dart-define=FLAVOR=bckiosk
```

**Output locations:**
- dedekiosk: `build/app/outputs/flutter-apk/app-dedekiosk-release.apk`
- bckiosk: `build/app/outputs/flutter-apk/app-bckiosk-release.apk`

#### Build App Bundle (for Play Store)

```bash
# dedekiosk flavor
flutter build appbundle --release --flavor dedekiosk --dart-define=ENVIRONMENT=PROD --dart-define=FLAVOR=dedekiosk

# bckiosk flavor
flutter build appbundle --release --flavor bckiosk --dart-define=ENVIRONMENT=PROD --dart-define=FLAVOR=bckiosk
```

**Output locations:**
- dedekiosk: `build/app/outputs/bundle/dedekioskRelease/app-dedekiosk-release.aab`
- bckiosk: `build/app/outputs/bundle/bckioskRelease/app-bckiosk-release.aab`

#### Build APK (Split by ABI)

To reduce APK size, build separate APKs for each CPU architecture:

```bash
# dedekiosk flavor
flutter build apk --release --flavor dedekiosk --dart-define=ENVIRONMENT=PROD --dart-define=FLAVOR=dedekiosk --split-per-abi

# bckiosk flavor
flutter build apk --release --flavor bckiosk --dart-define=ENVIRONMENT=PROD --dart-define=FLAVOR=bckiosk --split-per-abi
```

This will generate separate APKs for:
- `app-dedekiosk-armeabi-v7a-release.apk` (32-bit ARM)
- `app-dedekiosk-arm64-v8a-release.apk` (64-bit ARM)
- `app-dedekiosk-x86_64-release.apk` (64-bit x86)

### iOS

#### Build IPA (Release)

```bash
# dedekiosk flavor
flutter build ipa --release --flavor dedekiosk --dart-define=ENVIRONMENT=PROD --dart-define=FLAVOR=dedekiosk

# bckiosk flavor
flutter build ipa --release --flavor bckiosk --dart-define=ENVIRONMENT=PROD --dart-define=FLAVOR=bckiosk
```

**Note:** Before building iOS, ensure you have:
1. Created schemes in Xcode for both flavors (see CLAUDE.md)
2. Configured signing & capabilities in Xcode
3. Added bckiosk iOS app to Firebase Console (if needed)

### Windows

#### Build Windows Application

```bash
flutter build windows --release --dart-define=ENVIRONMENT=PROD
```

#### Build MSIX Installer

```bash
# Build Windows app first (if not already built)
flutter build windows --release --dart-define=ENVIRONMENT=PROD

# Create MSIX installer
flutter pub run msix:create --build-windows false --os-min-version 10.0.17134.83
```

## Automated Build & Upload Scripts

### Android (Linux/Mac)

Build and upload APK to FTP server:

```bash
./xbuild.sh
```

### Android (Windows)

Build and upload APK:

```bash
python .\apkupload.py
```

### Windows Application

Build and upload MSIX:

```bash
python .\windowsupload.py
```

## Environment Configuration

The app supports 3 environments:

| Environment | API Endpoint | Usage |
|-------------|-------------|-------|
| **DEV** | `https://api.dev.dedepos.com` | Development |
| **STAGING** | `https://api.uat.dedepos.com/v2` | Staging/UAT |
| **PROD** | `https://api.dedepos.com` | Production |

Set environment using `--dart-define=ENVIRONMENT=<env>`:

```bash
# Development
--dart-define=ENVIRONMENT=DEV

# Staging
--dart-define=ENVIRONMENT=STAGING

# Production
--dart-define=ENVIRONMENT=PROD
```

## VS Code Debug Configurations

The project includes pre-configured debug configurations in `.vscode/launch.json`:

- **dedekiosk (DEV)** - Debug mode with DEV environment
- **dedekiosk (PROD)** - Release mode with PROD environment
- **bckiosk (DEV)** - Debug mode with DEV environment
- **bckiosk (PROD)** - Release mode with PROD environment

Press **F5** in VS Code and select the desired configuration.

## Icon Generation

The project uses different icons for each flavor:

- **dedekiosk**: `assets/dedelogo.png`
- **bckiosk**: `assets/bclogo.png`

To regenerate icons:

```bash
# Generate dedekiosk icons
flutter pub run flutter_launcher_icons -f flutter_launcher_icons-dedekiosk.yaml

# Generate bckiosk icons
flutter pub run flutter_launcher_icons -f flutter_launcher_icons-bckiosk.yaml

# Or generate all
flutter pub run flutter_launcher_icons
```

## Testing

```bash
flutter test
```

## Code Analysis

```bash
flutter analyze
```

## Version Management

Version is defined in `pubspec.yaml`:

```yaml
version: 1.2.7+27  # format: <major>.<minor>.<patch>+<build_number>
```

Update both version string and build number when releasing.

## Firebase Configuration

### Adding bckiosk to Firebase (Production Setup)

1. Go to [Firebase Console](https://console.firebase.google.com/)
2. Select project "dedepos"
3. Add Android app:
   - Package name: `com.smlsoft.bckiosk`
   - Download `google-services.json` (already configured)
4. Add iOS app (if needed):
   - Bundle ID: `com.smlsoft.bckiosk`
   - Download `GoogleService-Info.plist`
   - Update `firebase_options.dart` with new iOS app ID

## Troubleshooting

### Google Services Error

If you get `No matching client found for package name 'com.smlsoft.bckiosk'`:
- Ensure the package is added to `google-services.json`
- Rebuild the project: `flutter clean && flutter pub get`

### Icon Size Issues

If icons appear too small:
- Icons use adaptive icons (Android 8.0+) for better appearance
- Regenerate icons using the commands above

### ObjectBox Errors

If you encounter ObjectBox schema errors:

```bash
flutter pub run build_runner build --delete-conflicting-outputs
```

## Documentation

For detailed architecture and development guidelines, see [CLAUDE.md](CLAUDE.md).

## License

Proprietary - SML Software Co., Ltd.
