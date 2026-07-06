/// 🗄️ LRU (Least Recently Used) Cache
///
/// Cache ที่จำกัดขนาด และลบ item ที่ไม่ได้ใช้งานนานที่สุดออกอัตโนมัติ
/// ใช้สำหรับ cache ข้อมูลที่ query บ่อยเพื่อลด DB access
///
/// **Features:**
/// - จำกัดขนาด (maxSize)
/// - Auto cleanup (ลบ LRU item เมื่อเต็ม)
/// - O(1) get/put operations
///
/// **Example:**
/// ```dart
/// final cache = LRUCache<String, ProductModel>(maxSize: 100);
/// cache.put('BARCODE001', product);
/// final product = cache.get('BARCODE001');
/// ```
class LRUCache<K, V> {
  final int maxSize;
  final Map<K, _CacheEntry<V>> _cache = {};
  final List<K> _accessOrder = [];

  LRUCache({required this.maxSize}) {
    assert(maxSize > 0, 'maxSize must be greater than 0');
  }

  /// ดึงข้อมูลจาก cache
  /// - คืนค่า null ถ้าไม่พบ
  /// - อัพเดท access order (ย้ายไปท้ายสุด = ใช้งานล่าสุด)
  V? get(K key) {
    final entry = _cache[key];
    if (entry != null) {
      // อัพเดท access order
      _accessOrder.remove(key);
      _accessOrder.add(key);
      return entry.value;
    }
    return null;
  }

  /// เพิ่มข้อมูลเข้า cache
  /// - ถ้าเต็มแล้ว จะลบ LRU item ออกก่อน
  /// - ถ้า key ซ้ำ จะ update value และ access order
  void put(K key, V value) {
    // ถ้ามี key อยู่แล้ว ให้ update และย้าย access order
    if (_cache.containsKey(key)) {
      _cache[key] = _CacheEntry(value);
      _accessOrder.remove(key);
      _accessOrder.add(key);
      return;
    }

    // ถ้าเต็มแล้ว ให้ลบ LRU item (item แรกใน list)
    if (_cache.length >= maxSize) {
      final lruKey = _accessOrder.removeAt(0);
      _cache.remove(lruKey);
    }

    // เพิ่ม entry ใหม่
    _cache[key] = _CacheEntry(value);
    _accessOrder.add(key);
  }

  /// ลบข้อมูลออกจาก cache
  void remove(K key) {
    _cache.remove(key);
    _accessOrder.remove(key);
  }

  /// ลบข้อมูลทั้งหมด
  void clear() {
    _cache.clear();
    _accessOrder.clear();
  }

  /// จำนวน items ปัจจุบัน
  int get length => _cache.length;

  /// เช็คว่ามี key อยู่หรือไม่
  bool containsKey(K key) => _cache.containsKey(key);

  /// ดึง keys ทั้งหมด
  Iterable<K> get keys => _cache.keys;

  /// ดึง values ทั้งหมด
  Iterable<V> get values => _cache.values.map((e) => e.value);

  /// สถิติการใช้งาน cache (สำหรับ debug)
  Map<String, dynamic> get stats => {
    'size': length,
    'maxSize': maxSize,
    'usage': '${(length / maxSize * 100).toStringAsFixed(1)}%',
    'accessOrder': _accessOrder.length,
  };
}

/// Entry ใน cache
class _CacheEntry<V> {
  final V value;

  _CacheEntry(this.value);
}
