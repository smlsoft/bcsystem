// ignore_for_file: non_constant_identifier_names

import 'package:flutter/foundation.dart';
import 'package:flutter/services.dart' show rootBundle;
import 'package:dedecashier/api/sync/model/promotion_model.dart';

/// 🎉 Mock Promotion Data
/// ไฟล์นี้เก็บข้อมูล promotion ทดสอบเพื่อแยกออกจาก pos_process.dart
/// เพื่อให้แก้ไขและจัดการได้ง่ายขึ้น
///
/// **หมายเหตุการคำนวณหน่วยนับ:**
/// - `qty`: จำนวนตามหน่วยที่ระบุ (ยังไม่แปลงเป็นหน่วยฐาน)
/// - `stand_value`: ตัวตั้ง (dividend) สำหรับแปลงหน่วย (default = 1)
/// - `dived_value`: ตัวหาร (divisor) สำหรับแปลงหน่วย (default = 1)
/// - `unit_code`, `unit_name`: ข้อมูลแสดงผลเท่านั้น
///
/// **สูตรคำนวณ:**
/// ```
/// base_qty = qty × (stand_value / dived_value)
/// ```
///
/// **ตัวอย่าง:**
/// - ซื้อ 1 กล่อง (stand_value=12, dived_value=1) = 12 ชิ้น (base unit)
/// - ซื้อ 1 ชิ้น (stand_value=1, dived_value=1) = 1 ชิ้น (base unit)

class PosMockPromotion {
  /// 🎉 โปรโมชั่นราคาพิเศษสินค้าก่อสร้าง (Type 4)
  ///
  /// **เงื่อนไข:**
  /// - ซื้อสินค้าตามที่กำหนด
  /// - ระหว่างวันที่ 25/10/2568 - 31/12/2568
  /// - ซื้อ 1 ชิ้นขึ้นไปได้ราคาพิเศษ
  ///
  /// **ผลลัพธ์:**
  /// - ขายราคาโปรโมชั่น
  /// - ผลต่างจากราคาปลีกให้นำไปเป็นส่วนลด
  ///
  /// **สินค้าทั้งหมด: 15 รายการ**
  /// - 🟫 กระเบื้อง: 5 รายการ (149-279 บาท)
  /// - 🚽 ชักโครก: 3 รายการ (1,659-2,259 บาท)
  /// - 🚰 อ่างล้างหน้า: 2 รายการ (389-789 บาท)
  /// - 💧 ชุดฉีดชำระ: 3 รายการ (89-179 บาท)
  /// - 🚿 ชุดฝักบัว: 2 รายการ (159-269 บาท)
  static PromotionMainModel getConstructionMaterialsPromotion() {
    return PromotionMainModel(
      promotion_list: [
        PromotionModel(
          type: 4, // ราคาพิเศษ
          index: 2,
          promotion_code: "MARINE2025-SPECIAL-001",
          date_begin: DateTime.parse("2025-10-23"),
          date_end: DateTime.parse("2025-12-31"),
          promotion_name: "โปรโมชั่นราคาพิเศษสินค้าก่อสร้าง 2568",
          discount_text: "",
          limit_qty: 1, // ซื้อ 1 ชิ้นขึ้นไปได้ราคาพิเศษ
          promotion_qty: 0,
          limit_amount: 0,
          customer_only: 0,
          promotion_item_code_include_list: [
            PromotionProductIncludeModel(
              promotion_product: [
                // ════════════════════════════════════════════════════════════
                // 🟫 กระเบื้อง (Tiles) - 5 รายการ
                // ════════════════════════════════════════════════════════════
                PromotionProductModel(
                  item_code: "10403436",
                  name: "60*60A MR BH7100-7 มังกรครีมนาโน ก.4",
                  unit_code: "B",
                  unit_name: "กล่อง",
                  qty: 1,
                  price: 169.00,
                  discount_text: "",
                ),
                PromotionProductModel(
                  item_code: "10301635",
                  name: "12*12A MR-S DG นวลนาถขาว ก.11",
                  unit_code: "B",
                  unit_name: "กล่อง",
                  qty: 1,
                  price: 149.00,
                  discount_text: "",
                ),
                PromotionProductModel(
                  item_code: "10342673",
                  name: "60*60A MR BA6230-X ครีมลายไม้เอ็กซ์ ก.4",
                  unit_code: "B",
                  unit_name: "กล่อง",
                  qty: 1,
                  price: 279.00,
                  discount_text: "",
                ),
                PromotionProductModel(
                  item_code: "10363873",
                  name: "16*16A MR-S DG อันโตนิโอไวท์ ก.6",
                  unit_code: "B",
                  unit_name: "กล่อง",
                  qty: 1,
                  price: 179.00,
                  discount_text: "",
                ),
                PromotionProductModel(
                  item_code: "10402009",
                  name: "10*16A MR-D RRM00001 ศิธา ก.10",
                  unit_code: "B",
                  unit_name: "กล่อง",
                  qty: 1,
                  price: 169.00,
                  discount_text: "",
                ),

                // ════════════════════════════════════════════════════════════
                // 🚽 สุขภัณฑ์ - ชักโครก (Toilets) - 3 รายการ
                // ════════════════════════════════════════════════════════════
                PromotionProductModel(
                  item_code: "10400747",
                  name: "ชักโครก MR-2777A-DF-S-WT",
                  unit_code: "ZWF",
                  unit_name: "ชุด",
                  qty: 1,
                  price: 2259.00,
                  discount_text: "",
                ),
                PromotionProductModel(
                  item_code: "10387435",
                  name: "ชักโครก MR-KZ214-S-WT",
                  unit_code: "ZWF",
                  unit_name: "ชุด",
                  qty: 1,
                  price: 1659.00,
                  discount_text: "",
                ),
                PromotionProductModel(
                  item_code: "10258715",
                  name: "ชักโครก MR-2111-S-WT",
                  unit_code: "ZWF",
                  unit_name: "ชุด",
                  qty: 1,
                  price: 2159.00,
                  discount_text: "",
                ),

                // ════════════════════════════════════════════════════════════
                // 🚰 สุขภัณฑ์ - อ่างล้างหน้า (Wash Basins) - 2 รายการ
                // ════════════════════════════════════════════════════════════
                PromotionProductModel(
                  item_code: "10258714",
                  name: "อ่างล้างหน้า MR B02+ขาตั้ง",
                  unit_code: "ZWF",
                  unit_name: "ชุด",
                  qty: 1,
                  price: 789.00,
                  discount_text: "",
                ),
                PromotionProductModel(
                  item_code: "10233731",
                  name: "อ่างล้างหน้า MR B65",
                  unit_code: "ZWF",
                  unit_name: "ชุด",
                  qty: 1,
                  price: 389.00,
                  discount_text: "",
                ),

                // ════════════════════════════════════════════════════════════
                // 💧 สุขภัณฑ์ - ชุดฉีดชำระ (Bidet Sprays) - 3 รายการ
                // ════════════════════════════════════════════════════════════
                PromotionProductModel(
                  item_code: "10393750",
                  name: "ชุดฉีดชำระ PVC ขาว ECO MR DHIU322_W",
                  unit_code: "ZWF",
                  unit_name: "ชุด",
                  qty: 1,
                  price: 89.00,
                  discount_text: "",
                ),
                PromotionProductModel(
                  item_code: "10240648",
                  name: "ชุดฉีดชำระโครเมี่ยม MR GB-102A+2",
                  unit_code: "ZWF",
                  unit_name: "ชุด",
                  qty: 1,
                  price: 179.00,
                  discount_text: "",
                ),
                PromotionProductModel(
                  item_code: "10401277",
                  name: "ชุดฉีดชำระ PVC HeadStrong MR-163 ขาว",
                  unit_code: "ZWF",
                  unit_name: "ชุด",
                  qty: 1,
                  price: 149.00,
                  discount_text: "",
                ),

                // ════════════════════════════════════════════════════════════
                // 🚿 สุขภัณฑ์ - ชุดฝักบัว (Shower Sets) - 2 รายการ
                // ════════════════════════════════════════════════════════════
                PromotionProductModel(
                  item_code: "10400705",
                  name: "ชุดฝักบัวโครม+วาล์ว 1F SAVE M219/303 MR",
                  unit_code: "ZWF",
                  unit_name: "ชุด",
                  qty: 1,
                  price: 269.00,
                  discount_text: "",
                ),
                PromotionProductModel(
                  item_code: "10400612",
                  name: "ชุดฝักบัวPVCขาว 1F Aqua Diamond MR M222",
                  unit_code: "ZWF",
                  unit_name: "ชุด",
                  qty: 1,
                  price: 159.00,
                  discount_text: "",
                ),
              ],
              include_product: [],
            ),
          ],
        ),
      ],
    );
  }

  /// 🎟️ โปรโมชั่น House Brand - หมุนวงล้อชิงรางวัล (Type 101)
  ///
  /// **เงื่อนไข:**
  /// - ซื้อสินค้า House Brand ครบ 2,000 บาท
  /// - วันที่ 25/10/2568 (วันเดียว)
  ///
  /// **ผลลัพธ์:**
  /// - ได้สิทธิ์หมุนวงล้อชิงรางวัล
  /// - แสดงคูปองท้ายใบเสร็จ
  ///
  /// **หมายเหตุ:**
  /// - ระบบจะตรวจสอบเฉพาะสินค้าที่มี `pattern_code = "HB"`
  /// - แสดงใน `promotion_coupon_list` เพื่อพิมพ์ท้ายบิล
  static PromotionMainModel getHouseBrandSpinWheelPromotion() {
    return PromotionMainModel(
      promotion_list: [
        PromotionModel(
          type: 101,
          index: 1,
          promotion_code: "MARINE2023-001",
          date_begin: DateTime.parse("2025-10-23"),
          date_end: DateTime.parse("2025-10-23"),
          promotion_name: "ซื้อครบ 2,000 บาท ได้หมุนวงล้อชิงรางวัล",
          discount_text: "",
          limit_qty: 0,
          limit_amount: 2000,
          promotion_qty: 1,
          promotion_item_code_include_list: [],
          promotion_house_brand_list: [
            PromotionHouseBrandModel(formatcode: "HB"),
          ],
        ),
      ],
    );
  }

  /// 🎁 โปรโมชั่นแลกของแถมตาม Tier (Type 102)
  ///
  /// **5 Tiers - Priority-based Selection**
  /// - Tier 5: 7,000฿ → พัดลมตั้งโต๊ะ (Priority 1 - ตรวจสอบก่อน)
  /// - Tier 4: 5,000฿ → กระทะไฟฟ้า (Priority 2)
  /// - Tier 3: 2,000฿ → กาต้มน้ำ (Priority 3)
  /// - Tier 2: 1,000฿ → ผ้ากันเปื้อน (Priority 4)
  /// - Tier 1: 0฿ → ถุงผ้า (Priority 5 - Fallback)
  ///
  /// **Logic:** ตรวจสอบ Priority 1 ก่อน ถ้าได้เลือก Tier นั้น ไม่เลือกอันอื่น
  ///
  /// **Date:** 25/10/2568 - 31/12/2568
  ///
  /// **Stock Management:** จำนวนคงเหลือจัดการผ่าน TierStockStruct (ObjectBox)
  static Future<PromotionMainModel> getTierRedemptionPromotions() async {
    // โหลดสินค้าจาก CSV แยกตาม Tier
    final tier5Products = await _loadTierProductsFromCsv(5);
    final tier4Products = await _loadTierProductsFromCsv(4);
    final tier3Products = await _loadTierProductsFromCsv(3);
    final tier2Products = await _loadTierProductsFromCsv(2);
    final tier1Products = await _loadTierProductsFromCsv(1);

    return PromotionMainModel(
      promotion_list: [
        _createTier(
          5,
          7000,
          1,
          "แลกรับของแถม Finext พัดลมตั้งโต๊ะ 16 นิ้ว",
          tier5Products,
        ),
        _createTier(
          4,
          5000,
          2,
          "แลกรับของแถม FINEXT กระทะไฟฟ้า",
          tier4Products,
        ),
        _createTier(
          3,
          2000,
          3,
          "แลกรับของแถม กาต้มน้ำไฟฟ้า2.0ลิตร",
          tier3Products,
        ),
        _createTier(2, 1000, 4, "แลกรับของแถม ผ้ากันเปื้อน", tier2Products),
        _createTier(1, 0, 5, "แลกรับของแถม ถุงผ้าน้ำเงิน", tier1Products),
      ],
    );
  }

  /// สร้าง Tier แต่ละระดับ
  ///
  /// **หมายเหตุ:** จำนวนคงเหลือจัดการผ่าน TierStockStruct (ObjectBox) แทน tier_display_count
  static PromotionModel _createTier(
    int tierLevel,
    double threshold,
    int priority,
    String rewardMessage,
    List<PromotionProductModel> products,
  ) {
    return PromotionModel(
      type: 102,
      index: tierLevel,
      promotion_code: "TIER-2025-00$tierLevel",
      date_begin: DateTime.parse("2025-10-23"),
      date_end: DateTime.parse("2025-12-31"),
      promotion_name: "โปรโมชั่นแลกของแถม Tier $tierLevel",
      discount_text: "",
      tier_threshold: threshold,
      tier_priority: priority,
      tier_reward_message: rewardMessage,
      tier_display_count: null, // ไม่ใช้แล้ว - ใช้ TierStockStruct แทน
      promotion_item_code_include_list: [
        PromotionProductIncludeModel(
          promotion_product: products,
          include_product: [],
        ),
      ],
    );
  }

  /// รายการสินค้าทั้งหมดที่ใช้ในโปรโมชั่น Tier
  /// แยกโหลดตาม Tier เพื่อลดขนาดไฟล์
  ///
  /// **โหลดจาก:** assets/tier_{tierLevel}_products.csv
  static Future<List<PromotionProductModel>> _loadTierProductsFromCsv(
    int tierLevel,
  ) async {
    try {
      final csvString = await rootBundle.loadString(
        'assets/tier_${tierLevel}_products.csv',
      );

      final List<String> lines = csvString.trim().split('\n');
      if (lines.length <= 1) {
        // ไฟล์ว่างหรือมีแค่ header
        if (kDebugMode) {
          print(
            '[TierPromotion] ⚠️ CSV file for Tier $tierLevel is empty or has no data',
          );
        }
        return [];
      }

      // Skip header line (first line)
      final dataLines = lines.skip(1);

      final products = <PromotionProductModel>[];

      for (final line in dataLines) {
        if (line.trim().isEmpty) continue;

        // Parse CSV line (handle commas in quoted strings)
        final fields = _parseCsvLine(line);

        if (fields.length < 6) {
          if (kDebugMode) {
            print('[TierPromotion] ⚠️ Invalid CSV line: $line');
          }
          continue;
        }

        // แปลง item_code เป็น String เสมอ (กรณีที่ CSV มาเป็นตัวเลข)
        final itemCode = fields[0].trim();
        final itemCodeString = itemCode.isEmpty ? '' : itemCode.toString();

        products.add(
          PromotionProductModel(
            item_code: itemCodeString,
            name: fields[1].trim(),
            unit_code: fields[2].trim(),
            unit_name: fields[3].trim(),
            qty: 1.0, // Default qty = 1
            price: 0.0, // Default price = 0 (free gift)
            stand_value: double.tryParse(fields[4].trim()) ?? 1.0,
            dived_value: double.tryParse(fields[5].trim()) ?? 1.0,
          ),
        );
      }

      if (kDebugMode) {
        print(
          '[TierPromotion] ✅ Loaded ${products.length} products for Tier $tierLevel from CSV',
        );
      }

      return products;
    } catch (e) {
      if (kDebugMode) {
        print(
          '[TierPromotion] ❌ Error loading tier_${tierLevel}_products.csv: $e',
        );
      }
      return [];
    }
  }

  /// Parse CSV line with support for quoted fields containing commas
  static List<String> _parseCsvLine(String line) {
    final List<String> fields = [];
    final buffer = StringBuffer();
    bool inQuotes = false;

    for (int i = 0; i < line.length; i++) {
      final char = line[i];

      if (char == '"') {
        inQuotes = !inQuotes;
      } else if (char == ',' && !inQuotes) {
        fields.add(buffer.toString());
        buffer.clear();
      } else {
        buffer.write(char);
      }
    }

    // Add last field
    fields.add(buffer.toString());

    return fields;
  }
}
