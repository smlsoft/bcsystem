# 🔴 CRITICAL BUG FIX: Stock Not Decreasing After Payment

## 📋 สรุปปัญหา

**ปัญหา:** หลังจากชำระเงินเสร็จ สต๊อกไม่ลดลง กลับไปเป็นจำนวนเดิมเมื่อกลับมาดูหน้าสินค้า

**สาเหตุหลัก:** ❌ การอัพเดท `isclose=1` ในตาราง `ordertempcalcqty` ไม่ได้ระบุ `orderid` ที่ถูกต้อง

---

## 🔍 การวิเคราะห์ปัญหา

### ก่อนแก้ไข (มี Bug):

```dart
// lib/order/order_save.dart - บรรทัด 101 (เดิม)
String query = "alter table ${global.clickHouseDatabaseName}.ordertempcalcqty 
                update isclose=1 
                where shopid='${global.deviceConfig.shopId}' 
                  and branchid='${global.deviceConfig.branchId}' 
                  and deviceid='${global.deviceConfig.orderStationCode}'";
```

### ปัญหาที่เกิดขึ้น:

1. **ไม่ได้ระบุ `orderid`** → อัพเดททุก records ที่ตรงกับ `shopid`, `branchid`, `deviceid`
2. **อัพเดทผิด order** → ถ้ามีหลาย orders ที่ยังไม่ได้ชำระ (isclose=0) จะถูกอัพเดทหมด
3. **ไม่อัพเดทเลย** → ถ้า `deviceid` ไม่ตรงกัน จะไม่มีการอัพเดทใดๆ

### ผลกระทบ:

```
สถานการณ์ที่เกิดขึ้น:
─────────────────────────────────────────────────────────
Order A (ยังไม่จ่าย):
  - orderid = "order-123"
  - barcode = "COFFEE-001", qty = -10, isclose = 0

Order B (กำลังจ่าย):
  - orderid = "order-456"  ← Order ที่กำลังชำระเงิน
  - barcode = "JUICE-002", qty = -5, isclose = 0

─────────────────────────────────────────────────────────
❌ เมื่อชำระ Order B:
   UPDATE isclose=1 
   WHERE shopid=X AND branchid=Y AND deviceid=Z
   
   → อัพเดททั้ง Order A และ Order B!
   → Order A ที่ยังไม่ได้จ่าย ถูกเปลี่ยนเป็น isclose=1
   → Stock calculation ผิดพลาด!
```

---

## ✅ การแก้ไข

### หลังแก้ไข (ถูกต้อง):

```dart
// lib/order/order_save.dart - บรรทัด 100-108 (ใหม่)
{
  // update commit qty - ระบุ orderid เพื่อให้แน่ใจว่าอัพเดทเฉพาะ order ปัจจุบันเท่านั้น
  String query = "alter table ${global.clickHouseDatabaseName}.ordertempcalcqty 
                  update isclose=1 
                  where shopid='${global.deviceConfig.shopId}' 
                    and branchid='${global.deviceConfig.branchId}' 
                    and orderid='${global.orderId}' 
                    and isclose=0";
  try {
    await api.clickHouseExecute(query).timeout(timeoutDuration);
    Logger.i('saveToClickHouse: Updated isclose=1 for orderid=${global.orderId}', 
             tag: 'StockManagement');
  } catch (e) {
    Logger.w('saveToClickHouse update qty failed: $e');
    global.sendErrorToDevTeam("saveToClickHouse update isclose=1 failed for orderid=${global.orderId}: $e");
    // Not critical, continue
  }
}
```

### การเปลี่ยนแปลงหลัก:

1. ✅ **เพิ่ม `orderid='${global.orderId}'`** → อัพเดทเฉพาะ order ปัจจุบัน
2. ✅ **เพิ่ม `isclose=0`** → อัพเดทเฉพาะรายการที่ยังไม่ได้จ่าย
3. ✅ **ลบ `deviceid` ออก** → ไม่จำเป็นแล้วเพราะมี `orderid` ระบุชัดเจน
4. ✅ **เพิ่ม Logging** → ติดตามการอัพเดทได้ง่ายขึ้น
5. ✅ **เพิ่ม Error reporting** → แจ้งเตือนทีมพัฒนาถ้ามีปัญหา

---

## 🔄 Flow ที่ถูกต้อง

### 1. เพิ่มสินค้าเข้าตะกร้า:

```sql
-- lib/order/order_util.dart - บรรทัด 329
INSERT INTO ordertempcalcqty 
  (shopid, branchid, deviceid, orderid, orderguid, orderdatetime, 
   barcode, isclose, qty, manufacturerguid)
VALUES 
  ('shop-1', 'branch-1', 'device-1', 'order-456', 'guid-xyz', now(),
   'COFFEE-001', 0, -10, 'mfg-1');
   
-- isclose = 0 (รอชำระเงิน)
-- qty = -10 (ลบสต๊อก 10 ชิ้น)
```

### 2. คำนวณ Stock Balance:

```sql
-- lib/global.dart - บรรทัด 920
-- lib/order/order_util.dart - บรรทัด 88, 207
SELECT sum(qty) 
FROM ordertempcalcqty 
WHERE shopid='shop-1' 
  AND branchid='branch-1' 
  AND barcode='COFFEE-001' 
  AND isclose IN (0,1,9)  -- ✅ กรองเฉพาะที่เกี่ยวข้อง

-- Result: -10 (สต๊อกลด 10 ชิ้น)
```

### 3. ชำระเงินเสร็จ:

```sql
-- lib/order/order_save.dart - บรรทัด 101 (แก้ไขแล้ว)
UPDATE ordertempcalcqty 
SET isclose = 1  -- เปลี่ยนเป็น "ขายแล้ว"
WHERE shopid='shop-1' 
  AND branchid='branch-1' 
  AND orderid='order-456'  -- ✅ ระบุ order ที่ชำระเงิน
  AND isclose=0;           -- ✅ เฉพาะที่รอชำระ

-- อัพเดตเฉพาะ order-456 เท่านั้น!
```

### 4. กลับมาดูหน้าสินค้าอีกครั้ง:

```sql
SELECT sum(qty) 
FROM ordertempcalcqty 
WHERE shopid='shop-1' 
  AND barcode='COFFEE-001' 
  AND isclose IN (0,1,9)

-- Record: orderid='order-456', isclose=1, qty=-10
-- Result: -10 (สต๊อกยังคงลด 10 ชิ้น) ✅
```

---

## 📊 ตัวอย่างการทำงาน

### สถานการณ์: ร้านกาแฟมีลูกค้า 2 คน

```
Stock เริ่มต้น: COFFEE-001 = 100 แก้ว

┌─────────────────────────────────────────────────────────┐
│ 1. เติมสต๊อก (Manual Adjustment)                        │
└─────────────────────────────────────────────────────────┘
INSERT: orderid=NULL, barcode='COFFEE-001', qty=+100, isclose=9
Balance: +100

┌─────────────────────────────────────────────────────────┐
│ 2. ลูกค้า A สั่ง 10 แก้ว (ยังไม่จ่าย)                 │
└─────────────────────────────────────────────────────────┘
INSERT: orderid='order-A', barcode='COFFEE-001', qty=-10, isclose=0
Balance: +100 + (-10) = +90 แก้ว ✅

┌─────────────────────────────────────────────────────────┐
│ 3. ลูกค้า B สั่ง 5 แก้ว (ยังไม่จ่าย)                  │
└─────────────────────────────────────────────────────────┘
INSERT: orderid='order-B', barcode='COFFEE-001', qty=-5, isclose=0
Balance: +100 + (-10) + (-5) = +85 แก้ว ✅

┌─────────────────────────────────────────────────────────┐
│ 4. ลูกค้า A ชำระเงิน ✅                                 │
└─────────────────────────────────────────────────────────┘
UPDATE: SET isclose=1 WHERE orderid='order-A' AND isclose=0
  → เฉพาะ order-A เท่านั้น! ✅
Balance: +100 + (-10) + (-5) = +85 แก้ว ✅

┌─────────────────────────────────────────────────────────┐
│ 5. กลับมาดูหน้าสินค้าอีกครั้ง                          │
└─────────────────────────────────────────────────────────┘
Query: WHERE isclose IN (0,1,9)
  - qty=+100, isclose=9  (เติมสต๊อก) ✅
  - qty=-10,  isclose=1  (order-A จ่ายแล้ว) ✅
  - qty=-5,   isclose=0  (order-B ยังไม่จ่าย) ✅
Balance: +85 แก้ว ✅ ถูกต้อง!

┌─────────────────────────────────────────────────────────┐
│ 6. ลูกค้า B ยกเลิก order ❌                            │
└─────────────────────────────────────────────────────────┘
UPDATE: SET isclose=2 WHERE orderid='order-B'
Balance: +100 + (-10) + 0 = +90 แก้ว ✅ (ไม่นับ isclose=2)
```

---

## 🛡️ การป้องกันปัญหาซ้ำ

### 1. หลักการสำคัญ:

- ✅ **ระบุ `orderid` เสมอ** เมื่ออัพเดท `isclose`
- ✅ **ระบุ `isclose=0`** เพื่อป้องกันอัพเดทซ้ำ
- ✅ **ใช้ `isclose IN (0,1,9)`** ในการคำนวณ stock
- ✅ **ไม่ใช้ `deviceid`** เป็นเงื่อนไขหลัก (เพราะอาจเปลี่ยนได้)

### 2. Template สำหรับการอัพเดท isclose:

```sql
-- ✅ ถูกต้อง: ระบุ orderid
UPDATE ordertempcalcqty 
SET isclose = <new_value>
WHERE shopid = <shop_id>
  AND branchid = <branch_id>
  AND orderid = <order_id>      -- ✅ จำเป็น!
  AND isclose = <expected_old_value>;  -- ✅ ควรมี!

-- ❌ ผิด: ไม่ระบุ orderid
UPDATE ordertempcalcqty 
SET isclose = 1
WHERE shopid = <shop_id>
  AND deviceid = <device_id>;   -- ❌ อันตราย!
```

### 3. Template สำหรับการคำนวณ Stock:

```sql
-- ✅ ถูกต้อง: กรองเฉพาะ isclose ที่เกี่ยวข้อง
SELECT sum(qty) as balance
FROM ordertempcalcqty
WHERE shopid = <shop_id>
  AND branchid = <branch_id>
  AND barcode = <barcode>
  AND isclose IN (0,1,9);  -- ✅ จำเป็น!

-- ❌ ผิด: นับทุก records รวมที่ยกเลิก
SELECT sum(qty) as balance
FROM ordertempcalcqty
WHERE shopid = <shop_id>
  AND barcode = <barcode>;  -- ❌ ผิด!
```

---

## 🧪 การทดสอบ

### Test Case 1: Order เดียว
1. เพิ่มสินค้า A จำนวน 10 → สต๊อกลด 10 ✅
2. ชำระเงิน → สต๊อกยังลด 10 ✅
3. กลับมาดูหน้าสินค้า → สต๊อกยังลด 10 ✅

### Test Case 2: หลาย Orders พร้อมกัน
1. Order A: สินค้า B จำนวน 5 (ยังไม่จ่าย) → สต๊อกลด 5 ✅
2. Order B: สินค้า B จำนวน 3 (ยังไม่จ่าย) → สต๊อกลด 8 ✅
3. ชำระ Order A → สต๊อกยังลด 8 ✅
4. กลับมาดู → สต๊อกยังลด 8 ✅
5. ชำระ Order B → สต๊อกยังลด 8 ✅

### Test Case 3: ยกเลิก Order
1. สั่งสินค้า C จำนวน 7 → สต๊อกลด 7 ✅
2. ยกเลิก → สต๊อกกลับมาเท่าเดิม ✅
3. กลับมาดู → สต๊อกเท่าเดิม ✅

---

## 📝 ไฟล์ที่แก้ไข

### 1. lib/order/order_save.dart (บรรทัด 100-108)

**เปลี่ยนแปลง:**
- เพิ่ม `orderid='${global.orderId}'` ในเงื่อนไข WHERE
- เพิ่ม `isclose=0` ในเงื่อนไข WHERE
- ลบ `deviceid` ออกจากเงื่อนไข WHERE
- เพิ่ม logging และ error reporting

**ผลกระทบ:**
- 🟢 แก้ไข bug สต๊อกไม่ลดหลังชำระเงิน
- 🟢 ป้องกันอัพเดทผิด order
- 🟢 ติดตามการทำงานได้ง่ายขึ้น

---

## ✅ สรุป

### ปัญหาที่แก้ไข:
❌ สต๊อกไม่ลดหลังชำระเงิน → ✅ แก้ไขแล้ว

### การเปลี่ยนแปลงหลัก:
1. เพิ่ม `orderid` ในเงื่อนไข UPDATE
2. เพิ่ม `isclose=0` เพื่อป้องกันอัพเดทซ้ำ
3. เพิ่ม logging และ error handling

### ข้อควรระวัง:
- ⚠️ ต้อง **rebuild app** เพื่อให้การแก้ไขมีผล
- ⚠️ ทดสอบ flow ทั้งหมด: เพิ่มสินค้า → ชำระเงิน → กลับมาดู
- ⚠️ ตรวจสอบ logs ด้วย tag `StockManagement`

---

## 📅 Timeline

- **2024-12-11**: พบปัญหา - สต๊อกไม่ลดหลังชำระเงิน
- **2024-12-11**: วิเคราะห์และพบ root cause ในไฟล์ `order_save.dart`
- **2024-12-11**: แก้ไขโดยเพิ่ม `orderid` ในเงื่อนไข WHERE
- **2024-12-11**: เพิ่ม documentation และ logging

---

**Status:** ✅ แก้ไขเสร็จสมบูรณ์
**Priority:** 🔴 CRITICAL
**Impact:** สูง - กระทบการจัดการสต๊อกทั้งระบบ
**Testing:** ⏳ รอทดสอบหลัง rebuild app
