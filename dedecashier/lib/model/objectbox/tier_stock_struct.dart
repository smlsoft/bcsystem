import 'package:objectbox/objectbox.dart';

/// 🎁 ObjectBox Entity สำหรับเก็บจำนวนสินค้าคงเหลือของแต่ละ Tier
///
/// **การใช้งาน:**
/// - Default: remaining_stock = 0 (ต้องตั้งค่าก่อนเริ่มขาย)
/// - หลังพิมพ์บิล: ลด remaining_stock ลง 1
/// - ถ้า remaining_stock <= 0: ไม่แสดง Tier นั้นใน promotion
/// - สามารถแก้ไขจำนวนได้จากหน้า POS (เมื่อมีของแถมมาเติม)
@Entity()
class TierStockStruct {
  @Id()
  int id = 0;

  /// ระดับ Tier (1-5)
  @Index()
  @Unique()
  int tier_level;

  /// รหัสโปรโมชั่น (เช่น "TIER-2025-001")
  @Index()
  String promotion_code;

  /// จำนวนสินค้าคงเหลือ (Default = 0, ต้องตั้งค่าก่อนใช้)
  int remaining_stock;

  /// วันที่อัปเดตล่าสุด
  @Property(type: PropertyType.date)
  DateTime updated_at;

  TierStockStruct({
    required this.tier_level,
    required this.promotion_code,
    this.remaining_stock = 0,
    DateTime? updated_at,
  }) : this.updated_at = updated_at ?? DateTime.now();

  /// ตรวจสอบว่ายังมีสินค้าคงเหลืออยู่หรือไม่
  bool get hasStock => remaining_stock > 0;

  /// ลดจำนวนสินค้าลง 1
  void decrementStock() {
    if (remaining_stock > 0) {
      remaining_stock--;
      updated_at = DateTime.now();
    }
  }

  /// เพิ่มจำนวนสินค้า
  void addStock(int amount) {
    remaining_stock += amount;
    updated_at = DateTime.now();
  }

  /// ตั้งค่าจำนวนสินค้า
  void setStock(int amount) {
    remaining_stock = amount;
    updated_at = DateTime.now();
  }

  @override
  String toString() {
    return 'TierStock(level: $tier_level, code: $promotion_code, stock: $remaining_stock, updated: $updated_at)';
  }
}
