import 'package:dedekiosk/global.dart' as global;

/// Kitchen Printer Cache for fast lookup
///
/// Instead of looping through all kitchens and products for EVERY product item,
/// we build a cache Map<barcode, kitchenPrinterName> once and reuse it.
///
/// Performance improvement: O(n*m) -> O(1) lookup
class KitchenPrinterCache {
  static final KitchenPrinterCache _instance = KitchenPrinterCache._internal();
  factory KitchenPrinterCache() => _instance;
  KitchenPrinterCache._internal();

  /// Cache map: barcode -> kitchen printer name
  Map<String, String> _cache = {};

  /// Last cache update time
  DateTime? _lastUpdate;

  /// Cache validity duration (5 minutes)
  static const Duration _cacheValidity = Duration(minutes: 5);

  /// Build or rebuild cache from global.shopProfile.kitchens
  void buildCache() {
    _cache.clear();

    if (global.deviceConfig.machineCondition == 0 &&
        global.shopProfile?.kitchens != null) {

      for (var kitchen in global.shopProfile!.kitchens!) {
        final kitchenName = global.getNameFromLanguage(
          kitchen.names,
          global.languageForCustomer
        );

        for (var barcode in kitchen.products) {
          // Map barcode to kitchen printer name
          _cache[barcode] = kitchenName;
        }
      }
    }

    _lastUpdate = DateTime.now();
  }

  /// Get kitchen printer name for a product barcode
  /// Returns empty string if not found
  String getKitchenPrinterName(String barcode) {
    // Rebuild cache if expired or not yet built
    if (_lastUpdate == null ||
        DateTime.now().difference(_lastUpdate!) > _cacheValidity) {
      buildCache();
    }

    return _cache[barcode] ?? '';
  }

  /// Force cache rebuild (call this when kitchen configuration changes)
  void invalidateCache() {
    _cache.clear();
    _lastUpdate = null;
  }

  /// Check if cache is valid
  bool get isValid {
    if (_lastUpdate == null) return false;
    return DateTime.now().difference(_lastUpdate!) <= _cacheValidity;
  }

  /// Get cache size (for debugging)
  int get cacheSize => _cache.length;
}
