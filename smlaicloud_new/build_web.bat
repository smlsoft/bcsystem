@echo off
echo Building Flutter web application for UAT environment

REM Set environment variables
set ENVIRONMENT=UAT

REM Clean and build web application
echo Cleaning previous builds...
flutter clean

echo Building web application...
flutter build web --release --web-renderer html

echo Web application built successfully! Files are in build/web directory.
