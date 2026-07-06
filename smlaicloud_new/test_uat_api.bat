@echo off
echo ===================================
echo Opening UAT API Test Page in Chrome
echo ===================================

set WEB_PORT=8090

echo Starting test server...
cd c:\gif\smlaicloud_new
start chrome http://localhost:%WEB_PORT%/uat_api_test.html

echo You can now test API connections in the opened browser tab
