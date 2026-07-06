# SMLAICloud

## วิธีการ Build และ Deploy ตาม Flavor

แอปพลิเคชันนี้มี 6 flavor

1. SML SMLAiCloud DEV
2. SML SMLAiCloud UAT
3. SML SMLAiCloud PROD
4. SML DoHome DEV
5. SML DoHome UAT
6. SML DoHome PROD

## การ Build สำหรับ Web

### SML SMLAiCloud DEV

host: https://smlai-cloud-dev-2.web.app

```bash
flutter build web -t lib/main_smlaidev.dart --release --no-tree-shake-icons
firebase deploy --only hosting:dev
```

### SML SMLAiCloud UAT

host: https://smlai-cloud-uat.web.app

```bash
set DART_VM_OPTIONS=--max-heap-size=4096m
flutter build web -t lib/main_smlaiuat.dart --release --no-tree-shake-icons
firebase deploy --only hosting:uat
```

### SML SMLAiCloud PROD

host: https://smlai-cloud.web.app

host: https://smlsoft.app

```bash
flutter build web -t lib/main_smlaiprod.dart --release --no-tree-shake-icons
firebase deploy --only hosting:smlai-cloud
```



### SML DoHome DEV

host: https://marine-merchant-dev.web.app

```bash
flutter build web -t lib/main_dohomedev.dart
firebase deploy --only hosting:dohome-dev
```

### SML DoHome UAT

host: https://marine-merchant-uat.web.app

```bash
set DART_VM_OPTIONS=--max-heap-size=4096m
flutter build web -t lib/main_dohomeuat.dart  --release --no-tree-shake-icons
firebase deploy --only hosting:dohome-uat
```

### SML DoHome PROD

host: https://marine-merchant-prod.web.app

```bash
flutter build web -t lib/main_dohomeprod.dart --release --no-tree-shake-icons
firebase deploy --only hosting:dohome-prod
```

โซลาว shop id : 2OJMVIo1Qi81NqYos3oDPoASziy

flutter pub run build_runner build
flutter pub run build_runner build --delete-conflicting-outputs

### ตัวอย่างการเพิ่ม host

```bash
firebase target:clear hosting dohome-dev
firebase target:apply hosting dohome-dev marine-merchant-dev

firebase target:clear hosting dohome-uat
firebase target:apply hosting dohome-uat marine-merchant-uat

firebase target:clear hosting dohome-prod
firebase target:apply hosting dohome-prod marine-merchant-prod
```
