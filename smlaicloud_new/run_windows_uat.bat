@echo off
echo ===================================
echo Running Flutter UAT in Windows Desktop
echo ===================================

echo Building and running the application in Windows Desktop...
cd c:\gif\smlaicloud_new
flutter clean
flutter pub get
flutter run -d windows --target=lib/main_smlaiuat.dart

pause
