#!/bin/bash
# Performance Testing Script for DeDe Kiosk
# Tests Phase 1 + Phase 2 optimizations

echo "=================================================="
echo "DeDe Kiosk Performance Testing Suite"
echo "Testing Phase 1 + Phase 2 Optimizations"
echo "=================================================="
echo ""

# Colors for output
GREEN='\033[0;32m'
RED='\033[0;31m'
YELLOW='\033[1;33m'
NC='\033[0m' # No Color

# Test results
TESTS_PASSED=0
TESTS_FAILED=0

# Function to print test result
print_result() {
    if [ $1 -eq 0 ]; then
        echo -e "${GREEN}✓ PASS${NC}: $2"
        ((TESTS_PASSED++))
    else
        echo -e "${RED}✗ FAIL${NC}: $2"
        ((TESTS_FAILED++))
    fi
}

echo "=================================================="
echo "Test 1: Build and Analyze"
echo "=================================================="
echo ""

echo "Running flutter analyze..."
flutter analyze > analyze_output.txt 2>&1
if [ $? -eq 0 ]; then
    print_result 0 "Code analysis passed"
else
    print_result 1 "Code analysis failed - check analyze_output.txt"
fi
echo ""

echo "=================================================="
echo "Test 2: Startup Time Test (Profile Mode)"
echo "=================================================="
echo ""

echo -e "${YELLOW}Manual Test Required:${NC}"
echo "1. Kill the app completely on your test device"
echo "2. Run: flutter run --profile"
echo "3. Measure time from app launch to first interactive frame"
echo "4. Expected: 1-2 seconds (previously 3-5 seconds)"
echo ""
echo "Press Enter when you've measured startup time..."
read

echo "Please enter measured startup time in seconds (e.g., 1.5):"
read STARTUP_TIME

# Check if startup time is within expected range
if (( $(echo "$STARTUP_TIME <= 2.5" | bc -l) )); then
    print_result 0 "Startup time: ${STARTUP_TIME}s (target: <2.5s)"
else
    print_result 1 "Startup time: ${STARTUP_TIME}s (target: <2.5s)"
fi
echo ""

echo "=================================================="
echo "Test 3: Memory Usage Test"
echo "=================================================="
echo ""

echo -e "${YELLOW}Manual Test Required:${NC}"
echo "1. Open Flutter DevTools: flutter pub global run devtools"
echo "2. Connect to your running app"
echo "3. Go to Memory tab"
echo "4. Note initial memory usage"
echo ""
echo "Initial memory target: <240MB (previously ~280MB)"
echo ""
echo "Please enter initial memory usage in MB (e.g., 220):"
read MEMORY_USAGE

if [ $MEMORY_USAGE -lt 240 ]; then
    print_result 0 "Initial memory: ${MEMORY_USAGE}MB (target: <240MB)"
else
    print_result 1 "Initial memory: ${MEMORY_USAGE}MB (target: <240MB)"
fi
echo ""

echo "=================================================="
echo "Test 4: Memory Leak Test"
echo "=================================================="
echo ""

echo -e "${YELLOW}Manual Test Required:${NC}"
echo "1. In Flutter DevTools Memory tab, take a snapshot"
echo "2. Perform 20+ payment transactions (open/close payment screens)"
echo "3. Take another snapshot"
echo "4. Check for TextEditingController leaks (should be 0)"
echo ""
echo "Are there any TextEditingController leaks? (y/n):"
read HAS_LEAKS

if [ "$HAS_LEAKS" == "n" ] || [ "$HAS_LEAKS" == "N" ]; then
    print_result 0 "No memory leaks detected"
else
    print_result 1 "Memory leaks detected - Phase 1 not working correctly"
fi
echo ""

echo "=================================================="
echo "Test 5: BLoC Lazy Loading Test"
echo "=================================================="
echo ""

echo -e "${YELLOW}Manual Test Required:${NC}"
echo "1. Restart the app"
echo "2. In Flutter DevTools, check BLoC instances"
echo "3. Should see only 2 BLoCs loaded initially (CategoryBloc, OrderTempBloc)"
echo ""
echo "How many BLoCs loaded at startup? (enter number):"
read BLOC_COUNT

if [ $BLOC_COUNT -le 3 ]; then
    print_result 0 "BLoC count at startup: ${BLOC_COUNT} (target: 2-3)"
else
    print_result 1 "BLoC count at startup: ${BLOC_COUNT} (target: 2-3)"
fi
echo ""

echo "=================================================="
echo "Test 6: Image Caching Test"
echo "=================================================="
echo ""

echo -e "${YELLOW}Manual Test Required:${NC}"
echo "1. Open the order screen and scroll through products"
echo "2. Go back to main page"
echo "3. Open order screen again and scroll to same products"
echo "4. Images should appear instantly (<100ms)"
echo ""
echo "Did images load instantly on second view? (y/n):"
read IMAGES_CACHED

if [ "$IMAGES_CACHED" == "y" ] || [ "$IMAGES_CACHED" == "Y" ]; then
    print_result 0 "Image caching working correctly"
else
    print_result 1 "Image caching not working - Phase 2 issue"
fi
echo ""

echo "=================================================="
echo "Test 7: Functional Regression Tests"
echo "=================================================="
echo ""

echo "Testing core functionality..."
echo ""

# Order Flow
echo "Can you complete a full order flow? (y/n):"
read ORDER_WORKS
if [ "$ORDER_WORKS" == "y" ]; then
    print_result 0 "Order flow works"
else
    print_result 1 "Order flow broken"
fi

# Payment
echo "Can you process a payment (any gateway)? (y/n):"
read PAYMENT_WORKS
if [ "$PAYMENT_WORKS" == "y" ]; then
    print_result 0 "Payment processing works"
else
    print_result 1 "Payment processing broken"
fi

# Printing
echo "Can you print a receipt? (y/n):"
read PRINT_WORKS
if [ "$PRINT_WORKS" == "y" ]; then
    print_result 0 "Printing works"
else
    print_result 1 "Printing broken"
fi

# KDS Screen
echo "Can you open KDS screen? (y/n):"
read KDS_WORKS
if [ "$KDS_WORKS" == "y" ]; then
    print_result 0 "KDS screen works (lazy BLoC loads correctly)"
else
    print_result 1 "KDS screen broken (lazy BLoC issue)"
fi

# Table Management
echo "Can you access table management? (y/n):"
read TABLE_WORKS
if [ "$TABLE_WORKS" == "y" ]; then
    print_result 0 "Table management works"
else
    print_result 1 "Table management broken"
fi

echo ""
echo "=================================================="
echo "Test Results Summary"
echo "=================================================="
echo ""

TOTAL_TESTS=$((TESTS_PASSED + TESTS_FAILED))
PASS_RATE=$((TESTS_PASSED * 100 / TOTAL_TESTS))

echo "Total Tests: $TOTAL_TESTS"
echo -e "Passed: ${GREEN}$TESTS_PASSED${NC}"
echo -e "Failed: ${RED}$TESTS_FAILED${NC}"
echo "Pass Rate: $PASS_RATE%"
echo ""

if [ $TESTS_FAILED -eq 0 ]; then
    echo -e "${GREEN}=================================================="
    echo "✓ ALL TESTS PASSED"
    echo "Ready for deployment!"
    echo -e "==================================================${NC}"
    exit 0
else
    echo -e "${RED}=================================================="
    echo "✗ SOME TESTS FAILED"
    echo "Fix issues before deployment"
    echo -e "==================================================${NC}"
    exit 1
fi
