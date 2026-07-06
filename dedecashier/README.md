# dedepos

A new Flutter project.

## 📚 User Guide Website

Deploy user guide to Firebase Hosting:
```bash
firebase deploy --only hosting
```
Live URL: https://bcaiposuserguide.web.app

### Edit User Guide Content
- แก้ไขเนื้อหาที่: `userguide/sections/*.html`
- แก้ไขหน้าหลักที่: `userguide/index.html`
- Deploy ใหม่หลังแก้ไข: `firebase deploy --only hosting`

# adb
adb -s TG36232441315 tcpip 5555
\scrcpy-win64-v2.0\scrcpy.exe -s TG36232441315

KeyStorePass : (see keystore.properties.example - do not commit real value)

flutter pub run build_runner build
flutter pub run build_runner build --delete-conflicting-outputs

mongodb://<USER>:<PASSWORD>@<HOST>:27017/?authMechanism=DEFAULT

-- สร้าง APP หลายตัว
flutter pub run flutter_flavorizr
flutter build appbundle --flavor smlmobilesales -t lib/main_smlmobilesales.dart --release

flutter build appbundle -t lib/main_dedepos.dart --release --dart-define=ENVIRONMENT=PROD --dart-define=FLAVOR=dedepos

flutter build appbundle --release --dart-define=ENVIRONMENT=PROD

// build dedecashier IOS
flutter build ipa --release --dart-define=ENVIRONMENT=PROD
flutter build apk --release --dart-define=ENVIRONMENT=PROD

huawei:agconnect
assets:download

flutter pub run flutter_flavorizr -p assets:download,assets:extract
flutter build windows 

flutter run --flavor dedepos -t lib/main_dedepos.dart  --dart-define=ENVIRONMENT=DEV

flutter build windows --flavor cashier -t lib/main_cashier.dart

flutter build windows --flavor dedepos -t lib/main_dedepos.dart

## Build Windows msix

## Build dedepos windows
```
flutter build windows -t lib/main_dedepos.dart --dart-define=ENVIRONMENT=PROD  --dart-define=FLAVOR=dedepos 
flutter pub run msix:create --build-windows false
```

## Build vfpos windows
```
flutter build windows -t lib/main_vfpos.dart --dart-define=ENVIRONMENT=PROD  --dart-define=FLAVOR=vfpos
dart run msix:create --build-windows false
python windowsupload.py
```
python apkupload.py

flutter pub run msix:create --publisher "CN=55D8FA38-A305-463E-8BA0-21DE7B40BA27" --display-name "DEDE POS" --identity-name "SMLSoft.DEDEPOS" --version "1.0.0.0" --capabilities "internetClient, location, microphone, webcam" --logo-path ".\assets\dede-pos-icon.png" --publisher-display-name "SMLSoft" 

## Flavor 

### Gen ios icons
```flutter pub run msix:create --build-windows false
flutter pub run flutter_flavorizr -p ios:icons  
```

## Build VF POS Command
```
flutter run --flaavor vfpos -t lib/main_vfpos.dart
flutter build windows --flavor vfpos -t lib/main_vfpos.dart
flutter pub run msix:create


```

## gen icon 
flutter pub run flutter_launcher_icons:main -f flutter_launcher_icons-dedecashier.yaml

flutter pub run flutter_launcher_icons:main -f flutter_launcher_icons-bcpos.yaml

flutter pub run flutter_launcher_icons:main -f flutter_launcher_icons-marinepos.yaml

## Build Marine POS
flutter run --flavor marinepos -t lib/main_marine.dart --release 
flutter build apk --flavor marinepos -t lib/main_marine.dart --release 

# build windows marinepos
flutter build windows --dart-define=FLAVOR=marinepos -t lib/main_marine.dart --release 
flutter pub run msix:create --build-windows false

## Build Cashier POS
flutter run --flavor dedecashier -t lib/main_cashier.dart --release 
flutter build apk --flavor dedecashier -t lib/main_cashier.dart --release 

flutter build ipa --flavor dedecashier -t lib/main_cashier.dart --release 
flutter build appbundle --flavor dedecashier -t lib/main_cashier.dart --release 
flutter build windows --dart-define=FLAVOR=dedecashier -t lib/main_cashier.dart --release 

## Build DEDE POS
flutter build apk --flavor dedepos -t lib/main_dedepos.dart --release 
flutter run --flavor dedepos -t lib/main_dedepos.dart --release 
flutter build windows --dart-define=FLAVOR=dedepos -t lib/main_dedepos.dart --release 
dart run msix:create --build-windows false

## Build BC POS
flutter run --flavor bcpos -t lib/main_bcpos.dart --release 
flutter build apk --flavor bcpos -t lib/main_bcpos.dart --release 
flutter build appbundle --flavor bcpos -t lib/main_bcpos.dart --release 
flutter build ipa --flavor bcpos -t lib/main_bcpos.dart --release 
flutter build windows --dart-define=FLAVOR=bcpos -t lib/main_bcpos.dart --release 
dart run msix:create --build-windows false
```dart
void main() async {
  F.appFlavor = Flavor.DEDEPOS;
  WidgetsFlutterBinding.ensureInitialized();
  Intl.defaultLocale = "th";
  await setUpServiceLocator();
  await initializeApp();
  //runApp(const App());
  runApp(App());
}

```

## Launch Config
```
{
    "version": "0.2.0",
    "configurations": [
        {
            "name": "vfpos",
            "request": "launch",
            "type": "dart",
            "program": "lib/main_vfpos.dart",
            "args": [
                "--flavor",
                "vfpos",
            ]
        },
    ]
}
```


## Change Target Platform macOS, ios

credit `https://stackoverflow.com/questions/63973136/the-ios-deployment-target-iphoneos-deployment-target-is-set-to-8-0-in-flutter`


IOS

```cli
☁  dedepos_new [main] ⚡  flutter pub run flutter_flavorizr -p ios:xcconfig,ios:buildTargets,ios:schema,ios:dummyAssets,ios:icons,ios:plist,ios:launchScreen 

```
platform :ios, '13.6'

...
...
...

post_install do |installer|
  installer.generated_projects.each do |project|
    project.targets.each do |target|
      target.build_configurations.each do |config|
        config.build_settings['IPHONEOS_DEPLOYMENT_TARGET'] = '13.6'
      end
    end
  end
end
```

MACOS

```
platform :macos, '11.5'

...
...
...

post_install do |installer|
  installer.generated_projects.each do |project|
    project.targets.each do |target|
      target.build_configurations.each do |config|
        config.build_settings['MACOSX_DEPLOYMENT_TARGET'] = '11.5'
      end
    end
  end
end
```


## Environment 

inspire from : https://stacksecrets.com/flutter/environment-configuration-in-flutter-app

### Run Command

```
flutter run --flavor vfpos -t lib/main_vfpos.dart --dart-define=ENVIRONMENT=PROD
flutter run --flavor vfpos -t lib/main_vfpos.dart --dart-define=ENVIRONMENT=STAGING
flutter run --flavor vfpos -t lib/main_vfpos.dart --dart-define=ENVIRONMENT=STAGING
```


### Run Dev
```
        {
            "name": "vfpos-production",
            "request": "launch",
            "type": "dart",
            "program": "lib/main_vfpos.dart",
            "args": [
                "--flavor",
                "vfpos"
            ]
        },
```

### Run Staging
```
        {
            "name": "vfpos-production",
            "request": "launch",
            "type": "dart",
            "program": "lib/main_vfpos.dart",
            "args": [
                "--flavor",
                "vfpos",
                "--dart-define",
                "ENVIRONMENT=STAGING"
            ]
        },
```

### Run Production
```
        {
            "name": "vfpos-production",
            "request": "launch",
            "type": "dart",
            "program": "lib/main_vfpos.dart",
            "args": [
                "--flavor",
                "vfpos",
                "--dart-define",
                "ENVIRONMENT=STAGING"
            ]
        },
```


webBot@19682511

flutter build --release



chatgpt api
OPENAI_API_KEY=<set in local environment>



ิปิดโต๊ะที่มีรายการยกเลิก
คิดเงิน
เปิดโต๊ะเดิม
สั่ง
ยกเลิก
ตอนปิดโต๊ะ มาเละ

<external service token - set in local environment>
