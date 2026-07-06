# Network Resilience Testing Guide

คู่มือการทดสอบ Network Resilience Improvements (Phase 1 + Phase 2)

---

## 🚀 วิธีเข้าถึง Test Page

### วิธีที่ 1: จาก Settings Page
1. เปิดแอพ DeDe Kiosk
2. ไปที่หน้า **Settings** (⚙️)
3. กดปุ่ม **"Network Test (Dev)"** (สีม่วง)

### วิธีที่ 2: จาก URL/Route
```dart
Navigator.pushNamed(context, '/network_test');
```

---

## 📋 Test Sections

Test Page แบ่งเป็น 5 sections:

### 1. Timeout Protection Tests (สีส้ม)
ทดสอบ timeout protection ที่เพิ่มเข้ามาใน Phase 1

**Tests:**
- ✅ Test clickHouseSelect with Timeout
- ✅ Test clickHouseExecute with Retry
- ✅ Test getMemberPin with Timeout

**สิ่งที่ควรเกิดขึ้น:**
- Query ควรเสร็จภายใน 10 วินาที
- ถ้า timeout จะแสดง error message
- Execute ควรมี retry mechanism (3 ครั้ง)

---

### 2. Loading Indicator Tests (สีน้ำเงิน)
ทดสอบ loading indicators จาก Phase 2

**Tests:**
- ✅ Test Basic Loading Overlay - แสดง loading 3 วินาที
- ✅ Test Loading with withLoadingIndicator - ทดสอบ helper function
- ✅ Test Loading with Cancel Button - แสดง loading พร้อมปุ่มยกเลิก
- ✅ Test Progress Sheet - แสดง progress 0-100%

**สิ่งที่ควรเกิดขึ้น:**
- Loading overlay แสดงขึ้นพร้อม message
- มี CircularProgressIndicator
- ปุ่ม Cancel ทำงาน (ถ้ามี)
- Progress bar แสดงความก้าวหน้า

---

### 3. Error Dialog Tests (สีแดง)
ทดสอบ error dialogs และ snackbars

**Tests:**
- ✅ Test Timeout Error Dialog - แสดง timeout error
- ✅ Test Connection Error Dialog - แสดง connection error
- ✅ Test Server Error Dialog - แสดง server error
- ✅ Test Error Snackbar - แสดง snackbar

**Error Type, Icon และสี:**

| Error Type | Icon | Color | Hint Message |
|-----------|------|-------|--------------|
| Timeout | ⏱️ access_time | Orange | เครือข่ายช้า ลองใหม่อีกครั้ง |
| No Connection | 📡 wifi_off | Red | ไม่มีอินเทอร์เน็ต ตรวจสอบ WiFi |
| Server Error | ⚠️ error_outline | Deep Orange | เซิร์ฟเวอร์ขัดข้อง ลองภายหลัง |
| Unknown | ⚠️ warning_amber | Amber | ข้อผิดพลาดไม่ทราบสาเหตุ |

---

### 4. Network Status Tests (สีเขียว)
ทดสอบการตรวจสอบ network

**Tests:**
- ✅ Test Network Availability Check
- ✅ Test executeWithRetry

---

### 5. Real Scenario Tests (สีม่วง)
ทดสอบสถานการณ์จริง

**Tests:**
- ✅ Simulate Stock Check Timeout
- ✅ Simulate Payment Processing
- ✅ Simulate Order Save with Retry

---

## ✅ Test Results Template

### Test Date: _______________
### Tested By: _______________
### Device: _______________
### Network: Good / Poor / Offline

#### Phase 1: Timeout Protection
- [ ] clickHouseSelect timeout: PASS / FAIL
- [ ] clickHouseExecute retry: PASS / FAIL
- [ ] getMemberPin timeout: PASS / FAIL

#### Phase 2: UX Feedback
- [ ] Loading overlays: PASS / FAIL
- [ ] Error dialogs: PASS / FAIL
- [ ] Network status: PASS / FAIL

**Notes:**
_______________________________________________

---

**Happy Testing! 🎉**
