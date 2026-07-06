@echo off
echo ===================================
echo Running Flutter UAT in Web Browser
echo ===================================

set FLUTTER_WEB_PORT=8080

REM Skip cleaning since it's time-consuming during testing
REM echo Cleaning previous builds...
REM flutter clean

echo Building and running the application in Chrome...
cd c:\gif\smlaicloud_new
flutter run -d chrome --web-port=%FLUTTER_WEB_PORT% --target=lib/main_smlaiuat.dart

pause
