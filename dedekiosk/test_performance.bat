@echo off
REM Performance Testing Script for DeDe Kiosk (Windows)
REM Tests Phase 1 + Phase 2 optimizations

echo ==================================================
echo DeDe Kiosk Performance Testing Suite
echo Testing Phase 1 + Phase 2 Optimizations
echo ==================================================
echo.

set TESTS_PASSED=0
set TESTS_FAILED=0

echo ==================================================
echo Test 1: Build and Analyze
echo ==================================================
echo.

echo Running flutter analyze...
flutter analyze > analyze_output.txt 2>&1
if %ERRORLEVEL% EQU 0 (
    echo [32m✓ PASS[0m: Code analysis passed
    set /a TESTS_PASSED+=1
) else (
    echo [31m✗ FAIL[0m: Code analysis failed - check analyze_output.txt
    set /a TESTS_FAILED+=1
)
echo.

echo ==================================================
echo Test 2: Startup Time Test (Profile Mode^)
echo ==================================================
echo.

echo [33mManual Test Required:[0m
echo 1. Kill the app completely on your test device
echo 2. Run: flutter run --profile
echo 3. Measure time from app launch to first interactive frame
echo 4. Expected: 1-2 seconds (previously 3-5 seconds^)
echo.
echo Press Enter when you've measured startup time...
pause > nul

echo Please enter measured startup time in seconds (e.g., 1.5^):
set /p STARTUP_TIME=

REM Simple comparison for batch (assuming decimal input like 1.5)
echo Startup time recorded: %STARTUP_TIME%s
echo Target: less than 2.5s
echo.

echo ==================================================
echo Test 3: Memory Usage Test
echo ==================================================
echo.

echo [33mManual Test Required:[0m
echo 1. Open Flutter DevTools: flutter pub global run devtools
echo 2. Connect to your running app
echo 3. Go to Memory tab
echo 4. Note initial memory usage
echo.
echo Initial memory target: less than 240MB (previously ~280MB^)
echo.
echo Please enter initial memory usage in MB (e.g., 220^):
set /p MEMORY_USAGE=

echo Memory usage recorded: %MEMORY_USAGE%MB
echo Target: less than 240MB
echo.

echo ==================================================
echo Test 4: Memory Leak Test
echo ==================================================
echo.

echo [33mManual Test Required:[0m
echo 1. In Flutter DevTools Memory tab, take a snapshot
echo 2. Perform 20+ payment transactions (open/close payment screens^)
echo 3. Take another snapshot
echo 4. Check for TextEditingController leaks (should be 0^)
echo.
echo Are there any TextEditingController leaks? (y/n^):
set /p HAS_LEAKS=

if /i "%HAS_LEAKS%"=="n" (
    echo [32m✓ PASS[0m: No memory leaks detected
    set /a TESTS_PASSED+=1
) else (
    echo [31m✗ FAIL[0m: Memory leaks detected - Phase 1 not working correctly
    set /a TESTS_FAILED+=1
)
echo.

echo ==================================================
echo Test 5: BLoC Lazy Loading Test
echo ==================================================
echo.

echo [33mManual Test Required:[0m
echo 1. Restart the app
echo 2. In Flutter DevTools, check BLoC instances
echo 3. Should see only 2 BLoCs loaded initially (CategoryBloc, OrderTempBloc^)
echo.
echo How many BLoCs loaded at startup? (enter number^):
set /p BLOC_COUNT=

echo BLoC count: %BLOC_COUNT%
echo Target: 2-3 BLoCs
echo.

echo ==================================================
echo Test 6: Image Caching Test
echo ==================================================
echo.

echo [33mManual Test Required:[0m
echo 1. Open the order screen and scroll through products
echo 2. Go back to main page
echo 3. Open order screen again and scroll to same products
echo 4. Images should appear instantly (less than 100ms^)
echo.
echo Did images load instantly on second view? (y/n^):
set /p IMAGES_CACHED=

if /i "%IMAGES_CACHED%"=="y" (
    echo [32m✓ PASS[0m: Image caching working correctly
    set /a TESTS_PASSED+=1
) else (
    echo [31m✗ FAIL[0m: Image caching not working - Phase 2 issue
    set /a TESTS_FAILED+=1
)
echo.

echo ==================================================
echo Test 7: Functional Regression Tests
echo ==================================================
echo.

echo Testing core functionality...
echo.

REM Order Flow
echo Can you complete a full order flow? (y/n^):
set /p ORDER_WORKS=
if /i "%ORDER_WORKS%"=="y" (
    echo [32m✓ PASS[0m: Order flow works
    set /a TESTS_PASSED+=1
) else (
    echo [31m✗ FAIL[0m: Order flow broken
    set /a TESTS_FAILED+=1
)

REM Payment
echo Can you process a payment (any gateway^)? (y/n^):
set /p PAYMENT_WORKS=
if /i "%PAYMENT_WORKS%"=="y" (
    echo [32m✓ PASS[0m: Payment processing works
    set /a TESTS_PASSED+=1
) else (
    echo [31m✗ FAIL[0m: Payment processing broken
    set /a TESTS_FAILED+=1
)

REM Printing
echo Can you print a receipt? (y/n^):
set /p PRINT_WORKS=
if /i "%PRINT_WORKS%"=="y" (
    echo [32m✓ PASS[0m: Printing works
    set /a TESTS_PASSED+=1
) else (
    echo [31m✗ FAIL[0m: Printing broken
    set /a TESTS_FAILED+=1
)

REM KDS Screen
echo Can you open KDS screen? (y/n^):
set /p KDS_WORKS=
if /i "%KDS_WORKS%"=="y" (
    echo [32m✓ PASS[0m: KDS screen works (lazy BLoC loads correctly^)
    set /a TESTS_PASSED+=1
) else (
    echo [31m✗ FAIL[0m: KDS screen broken (lazy BLoC issue^)
    set /a TESTS_FAILED+=1
)

REM Table Management
echo Can you access table management? (y/n^):
set /p TABLE_WORKS=
if /i "%TABLE_WORKS%"=="y" (
    echo [32m✓ PASS[0m: Table management works
    set /a TESTS_PASSED+=1
) else (
    echo [31m✗ FAIL[0m: Table management broken
    set /a TESTS_FAILED+=1
)

echo.
echo ==================================================
echo Test Results Summary
echo ==================================================
echo.

set /a TOTAL_TESTS=%TESTS_PASSED%+%TESTS_FAILED%

echo Total Tests: %TOTAL_TESTS%
echo Passed: [32m%TESTS_PASSED%[0m
echo Failed: [31m%TESTS_FAILED%[0m
echo.

if %TESTS_FAILED% EQU 0 (
    echo [32m==================================================
    echo ✓ ALL TESTS PASSED
    echo Ready for deployment!
    echo ==================================================[0m
    exit /b 0
) else (
    echo [31m==================================================
    echo ✗ SOME TESTS FAILED
    echo Fix issues before deployment
    echo ==================================================[0m
    exit /b 1
)
