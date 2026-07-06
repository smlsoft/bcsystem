# คู่มือทดสอบ Slip Upload บน Android

## วันที่: 12 ธันวาคม 2025

---

## 🎯 วัตถุประสงค์
ทดสอบการบันทึกและส่ง slip ขึ้น server บน Android device เพื่อหาสาเหตุที่ slip ไม่ถูกส่ง

---

## ✅ การเตรียมความพร้อม

### 1. ตรวจสอบ Permissions (AndroidManifest.xml)
```xml
<!-- android/app/src/main/AndroidManifest.xml -->
<manifest>
    <!-- Required permissions -->
    <uses-permission android:name="android.permission.INTERNET"/>
    <uses-permission android:name="android.permission.ACCESS_NETWORK_STATE"/>
    
    <!-- Optional but recommended -->
    <uses-permission android:name="android.permission.WAKE_LOCK"/>
</manifest>
```

**✅ สิ่งที่ต้องเช็ค:**
- มี INTERNET permission
- มี ACCESS_NETWORK_STATE permission

---

### 2. Build และ Install
```powershell
# Build release APK
flutter build apk --release

# หรือ build debug APK (เพื่อดู log)
flutter build apk --debug

# Install to device
flutter install
```

---

## 🧪 ขั้นตอนการทดสอบ

### Test Case 1: ทดสอบการบันทึก Slip

#### 1. เริ่มต้น
```powershell
# เชื่อมต่อ device และเปิด log viewer
adb logcat -c  # Clear old logs
adb logcat | Select-String "SlipSave"
```

#### 2. ทำรายการชำระเงิน
1. เปิดแอพ Kiosk
2. สั่งสินค้า
3. กดชำระเงิน
4. รอให้การชำระเงินสำเร็จ

#### 3. ตรวจสอบ Log
**Log ที่ต้องเห็น:**
```
I/SlipSave: 🔵 START: Saving slip to file
I/SlipSave: 🔵 docNumber: xxx
I/SlipSave: 🔵 memberPinCode: xxx
I/SlipSave: 🔵 Directory path: /data/data/.../orderstationbill
I/SlipSave: 🔵 Directory exists: true
I/SlipSave: 🔵 Full file path: /data/data/.../orderstationbill/xxx.jpg
I/SlipSave: 🔵 Image decoded successfully
I/SlipSave: 🔵 Image encoded to JPG (quality: 25)
I/SlipSave: ✅ Slip saved successfully: /data/data/.../xxx.jpg (12345 bytes)
```

**❌ ถ้าเจอ Error:**
```
E/SlipSave: ❌ Failed to save slip
E/SlipSave: Error: [error message]
```

#### 4. ตรวจสอบไฟล์
```powershell
# List files in slip directory
adb shell "run-as com.dedekiosk.app ls -la /data/data/com.dedekiosk.app/app_flutter/orderstationbill/"

# หรือ pull ไฟล์มาดู
adb shell "run-as com.dedekiosk.app cat /data/data/com.dedekiosk.app/app_flutter/orderstationbill/xxx.jpg" > slip.jpg
```

---

### Test Case 2: ทดสอบ Upload Worker

#### 1. เริ่มต้น
```powershell
# เชื่อมต่อ device และเปิด log viewer
adb logcat -c  # Clear old logs
adb logcat | Select-String "SlipUpload"
```

#### 2. รอ Timer ทำงาน
- Timer จะเรียก `uploadSlipWorker()` ทุก 5 วินาที
- รอ 5-10 วินาทีหลังชำระเงิน

#### 3. ตรวจสอบ Log
**Log ที่ต้องเห็น:**
```
I/SlipUpload: 🔵 uploadSlipWorker: START
I/SlipUpload: 🔵 shopId: xxx
I/SlipUpload: 🔵 branchId: xxx
I/SlipUpload: 🔵 deviceCode: xxx
I/SlipUpload: 🔵 Checking internet connection...
I/SlipUpload: 🔵 Internet connection: true
I/SlipUpload: 🔵 App documents directory: /data/data/...
I/SlipUpload: 🔵 Slip directory: /data/data/.../orderstationbill
I/SlipUpload: 🔵 Directory exists: true
I/SlipUpload: 🔵 Total files in directory: 1
I/SlipUpload: 🔵 Found 1 JPG files to process
I/SlipUpload: 🔵 File: xxx.jpg
I/SlipUpload: uploadSlipWorker: Processing xxx.jpg (docNo: xxx, member: xxx)
I/SlipUpload: 🔵 File size: 12345 bytes
I/SlipUpload: 🔵 Upload attempt 1/3 - xxx.jpg
I/SlipUpload: 🔵 Upload result: success=true, message=OK
I/SlipUpload: uploadSlipWorker: Upload success - xxx.jpg (attempt 1)
I/SlipUpload: uploadSlipWorker: Completed - all 1 files uploaded successfully
```

**⚠️ Warning ที่อาจเจอ:**
```
W/SlipUpload: uploadSlipWorker: Already running, skipping...
```
→ ปกติ เกิดจากการเรียก 2 ครั้งพร้อมกัน (มี lock ป้องกัน)

```
W/SlipUpload: uploadSlipWorker: No internet connection, skipping...
```
→ เช็คการเชื่อมต่อ internet

```
W/SlipUpload: uploadSlipWorker: Directory does not exist
```
→ ไฟล์ไม่ถูกบันทึก หรือ path ผิด

```
W/SlipUpload: uploadSlipWorker: No slip files to upload
```
→ ไม่มีไฟล์ในโฟลเดอร์ (อาจถูกลบไปแล้ว)

**❌ Error ที่อาจเจอ:**
```
W/SlipUpload: uploadSlipWorker: Timeout (attempt 1) - xxx.jpg
```
→ Network ช้า หรือ server ไม่ตอบสนอง

```
W/SlipUpload: uploadSlipWorker: Upload failed (attempt 1) - xxx.jpg, reason: [error]
```
→ API error (ต้องดู error message)

```
E/SlipUpload: uploadSlipWorker: Critical error
```
→ Error ร้ายแรง (ดู stack trace)

---

## 🔍 การวินิจฉัยปัญหา

### ปัญหา 1: Slip ไม่ถูกบันทึก

**Symptoms:**
- ไม่เห็น log "✅ Slip saved successfully"
- มี log "❌ Failed to save slip"

**สาเหตุที่เป็นไปได้:**
1. ❌ Permission ไม่ถูกต้อง
2. ❌ Path ไม่สามารถเขียนได้
3. ❌ Image encoding failed
4. ❌ Memory ไม่พอ

**แก้ไข:**
```dart
// ตรวจสอบ permission ใน AndroidManifest.xml
// ตรวจสอบ path ว่าถูกต้อง
// ตรวจสอบ memory

// ลอง log error message:
Logger.e("❌ Failed to save slip", error: e, stackTrace: s, tag: 'SlipSave');
```

---

### ปัญหา 2: Upload Worker ไม่ทำงาน

**Symptoms:**
- ไม่เห็น log "🔵 uploadSlipWorker: START"
- Timer ไม่ถูกเรียก

**สาเหตุที่เป็นไปได้:**
1. ❌ `shopId` ยังว่าง (ยังไม่ได้เชื่อมต่อ)
2. ❌ `checkOrderActive` = true (กำลังทำงานอยู่)
3. ❌ App ถูก pause หรือ background

**แก้ไข:**
```dart
// ตรวจสอบว่า shopId มีค่า
Logger.d("shopId: ${global.deviceConfig.shopId}");

// ตรวจสอบว่า timer ทำงาน
// ใน main.dart:
Logger.d("Timer 3 tick - checkOrderActive: ${global.checkOrderActive}");
```

---

### ปัญหา 3: ไม่มี Internet Connection

**Symptoms:**
- เห็น log "No internet connection, skipping..."
- `hasInternet = false`

**สาเหตุที่เป็นไปได้:**
1. ❌ Device ไม่ได้เชื่อมต่อ Wi-Fi/Mobile data
2. ❌ `InternetAddress.lookup('google.com')` ถูกบล็อก
3. ❌ Permission `ACCESS_NETWORK_STATE` ไม่มี

**แก้ไข:**
```dart
// เช็ค internet connection
final hasInternet = await _hasInternetConnection();
Logger.d("Internet: $hasInternet");

// หรือใช้ package: connectivity_plus
```

---

### ปัญหา 4: Upload Failed

**Symptoms:**
- เห็น log "Upload failed after 3 attempts"
- มี error message จาก API

**สาเหตุที่เป็นไปได้:**
1. ❌ API endpoint ผิด
2. ❌ Authentication failed
3. ❌ File format ไม่ถูกต้อง
4. ❌ Network timeout
5. ❌ SSL certificate error

**แก้ไข:**
```dart
// เช็ค API response
Logger.d("Upload result: ${uploadResult.message}");

// เช็ค network timeout
// ปัจจุบันตั้งไว้ 30 วินาที

// เช็ค SSL certificate
// อาจต้อง allow self-signed certificate ใน debug mode
```

---

## 📋 Checklist

### ก่อนทดสอบ:
- [ ] Build APK เรียบร้อย
- [ ] Install ใน device สำเร็จ
- [ ] Device เชื่อมต่อ internet
- [ ] Device มี permission ครบ
- [ ] adb logcat พร้อมใช้งาน

### ขณะทดสอบ Test Case 1:
- [ ] สั่งสินค้าได้
- [ ] ชำระเงินสำเร็จ
- [ ] เห็น log "🔵 START: Saving slip"
- [ ] เห็น log "✅ Slip saved successfully"
- [ ] เห็น path ที่บันทึก
- [ ] เห็น file size
- [ ] ไม่มี error log

### ขณะทดสอบ Test Case 2:
- [ ] รอ 5 วินาทีหลังชำระเงิน
- [ ] เห็น log "🔵 uploadSlipWorker: START"
- [ ] เห็น log "Internet connection: true"
- [ ] เห็น log "Found X JPG files"
- [ ] เห็น log "Upload attempt 1/3"
- [ ] เห็น log "Upload success"
- [ ] ไฟล์ถูกลบหลัง upload สำเร็จ
- [ ] ไม่มี error log

### หลังทดสอบ:
- [ ] บันทึก log ทั้งหมด
- [ ] บันทึก error (ถ้ามี)
- [ ] ตรวจสอบว่า slip ขึ้น server
- [ ] สรุปผลการทดสอบ

---

## 🎯 Expected Results

### ✅ การทดสอบสำเร็จ:
1. ✅ Slip ถูกบันทึกเป็นไฟล์ `.jpg`
2. ✅ ไฟล์มีขนาดประมาณ 10-50 KB
3. ✅ Upload Worker ทำงานทุก 5 วินาที
4. ✅ Upload สำเร็จภายใน 30 วินาที
5. ✅ ไฟล์ถูกลบหลัง upload สำเร็จ
6. ✅ Slip ปรากฏบน server

### ❌ การทดสอบล้มเหลว:
1. ❌ Slip ไม่ถูกบันทึก → ดู Test Case 1
2. ❌ Upload Worker ไม่ทำงาน → ดู Test Case 2
3. ❌ Upload failed → ดู "ปัญหา 4"
4. ❌ Slip ไม่ขึ้น server → ตรวจสอบ API

---

## 🔧 Debug Commands

### ดู Log แบบ Real-time
```powershell
# All logs with SlipSave and SlipUpload tags
adb logcat | Select-String "SlipSave|SlipUpload"

# Only SlipSave
adb logcat | Select-String "SlipSave"

# Only SlipUpload
adb logcat | Select-String "SlipUpload"

# With timestamp
adb logcat -v time | Select-String "SlipSave|SlipUpload"
```

### ดู Files ใน Device
```powershell
# List files
adb shell "run-as com.dedekiosk.app ls -la /data/data/com.dedekiosk.app/app_flutter/orderstationbill/"

# Count files
adb shell "run-as com.dedekiosk.app ls /data/data/com.dedekiosk.app/app_flutter/orderstationbill/ | wc -l"

# Check directory exists
adb shell "run-as com.dedekiosk.app ls -d /data/data/com.dedekiosk.app/app_flutter/orderstationbill/"
```

### Pull File จาก Device
```powershell
# Pull specific file
adb shell "run-as com.dedekiosk.app cat /data/data/com.dedekiosk.app/app_flutter/orderstationbill/xxx.jpg" > slip.jpg

# Check file size on device
adb shell "run-as com.dedekiosk.app ls -lh /data/data/com.dedekiosk.app/app_flutter/orderstationbill/xxx.jpg"
```

### Clear Test Data
```powershell
# Delete all slip files
adb shell "run-as com.dedekiosk.app rm /data/data/com.dedekiosk.app/app_flutter/orderstationbill/*.jpg"

# Clear app data (reset app)
adb shell pm clear com.dedekiosk.app
```

---

## 📊 Test Report Template

### ข้อมูลการทดสอบ:
- **วันที่:** [date]
- **Device:** [model]
- **Android Version:** [version]
- **App Version:** [version]
- **Network:** [WiFi/Mobile data]

### ผลการทดสอบ Test Case 1:
- **ผลลัพธ์:** ✅ สำเร็จ / ❌ ล้มเหลว
- **Log:** [attach log]
- **File Path:** [path]
- **File Size:** [size] bytes
- **Error (ถ้ามี):** [error message]

### ผลการทดสอบ Test Case 2:
- **ผลลัพธ์:** ✅ สำเร็จ / ❌ ล้มเหลว
- **Upload Time:** [seconds]
- **Retry Count:** [count]
- **Log:** [attach log]
- **Error (ถ้ามี):** [error message]

### สรุป:
- **ปัญหาที่พบ:** [description]
- **สาเหตุ:** [root cause]
- **แนวทางแก้ไข:** [solution]

---

## 📁 ไฟล์ที่เกี่ยวข้อง:
- ✅ `lib/print/print.dart` - บันทึก slip
- ✅ `lib/order/order_util.dart` - upload worker
- ✅ `lib/order/order_save.dart` - เรียก print queue
- ✅ `lib/main.dart` - timer
- ⚠️ `lib/api/api.dart` - API functions
- ⚠️ `android/app/src/main/AndroidManifest.xml` - permissions

---

## 📞 ติดต่อ Support
ถ้าพบปัญหาที่แก้ไม่ได้:
1. เก็บ log ทั้งหมด
2. Screenshot error
3. บันทึก test report
4. ส่งให้ทีมพัฒนา
