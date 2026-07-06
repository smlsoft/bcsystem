import 'dart:typed_data';
import 'dart:ui' as ui;
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:dedecashier/core/logger/app_logger.dart';

class AppImageCacheManager {
  static AppImageCacheManager? _instance;
  static AppImageCacheManager get instance =>
      _instance ??= AppImageCacheManager._();

  AppImageCacheManager._();

  static final Map<String, ui.Image> _assetCache = {};
  static final Map<String, Widget> _widgetCache = {};

  static const int maxCacheSize = 100;

  static Future<ui.Image?> loadAssetImage(String assetPath) async {
    try {
      if (_assetCache.containsKey(assetPath)) {
        return _assetCache[assetPath];
      }

      if (_assetCache.length >= maxCacheSize) {
        var firstKey = _assetCache.keys.first;
        _assetCache.remove(firstKey);
      }

      final ByteData data = await rootBundle.load(assetPath);
      final ui.Codec codec = await ui.instantiateImageCodec(
        data.buffer.asUint8List(),
      );
      final ui.FrameInfo frameInfo = await codec.getNextFrame();

      _assetCache[assetPath] = frameInfo.image;

      return frameInfo.image;
    } catch (e) {
      AppLogger.error('Error loading asset image $assetPath: $e');
      return null;
    }
  }

  static Widget getCachedAssetImage(
    String assetPath, {
    double? width,
    double? height,
    BoxFit? fit,
    Color? color,
  }) {
    String cacheKey = '$assetPath-$width-$height-$fit-$color';

    if (_widgetCache.containsKey(cacheKey)) {
      return _widgetCache[cacheKey]!;
    }

    if (_widgetCache.length >= maxCacheSize) {
      var firstKey = _widgetCache.keys.first;
      _widgetCache.remove(firstKey);
    }

    Widget imageWidget = Image.asset(
      assetPath,
      width: width,
      height: height,
      fit: fit,
      color: color,
      // ปิด Cache ของ Flutter เพราะเราใช้ Cache ของเราเอง
      cacheWidth: width?.round(),
      cacheHeight: height?.round(),
    );

    _widgetCache[cacheKey] = imageWidget;

    return imageWidget;
  }

  static Widget getCachedNetworkImage(
    String url, {
    double? width,
    double? height,
    BoxFit? fit,
    Widget? placeholder,
    Widget? errorWidget,
  }) {
    String cacheKey = '$url-$width-$height-$fit';

    if (_widgetCache.containsKey(cacheKey)) {
      return _widgetCache[cacheKey]!;
    }

    if (_widgetCache.length >= maxCacheSize) {
      var firstKey = _widgetCache.keys.first;
      _widgetCache.remove(firstKey);
    }

    Widget imageWidget = Image.network(
      url,
      width: width,
      height: height,
      fit: fit,
      loadingBuilder: (context, child, loadingProgress) {
        if (loadingProgress == null) return child;
        return placeholder ??
            Center(
              child: CircularProgressIndicator(
                value: loadingProgress.expectedTotalBytes != null
                    ? loadingProgress.cumulativeBytesLoaded /
                          loadingProgress.expectedTotalBytes!
                    : null,
              ),
            );
      },
      errorBuilder: (context, error, stackTrace) {
        return errorWidget ?? const Icon(Icons.error);
      },
    );

    _widgetCache[cacheKey] = imageWidget;

    return imageWidget;
  }

  static void clearCache() {
    _assetCache.clear();
    _widgetCache.clear();
    AppLogger.debug('AppImageCacheManager: Cache cleared');
  }

  static void clearAssetCache(String assetPath) {
    _assetCache.remove(assetPath);

    _widgetCache.removeWhere((key, value) => key.startsWith(assetPath));
  }

  static void performCleanup() {
    if (_assetCache.length > maxCacheSize * 0.8) {
      int removeCount = (_assetCache.length * 0.2).round();
      var keysToRemove = _assetCache.keys.take(removeCount).toList();

      for (var key in keysToRemove) {
        _assetCache.remove(key);
      }
    }

    if (_widgetCache.length > maxCacheSize * 0.8) {
      int removeCount = (_widgetCache.length * 0.2).round();
      var keysToRemove = _widgetCache.keys.take(removeCount).toList();

      for (var key in keysToRemove) {
        _widgetCache.remove(key);
      }
    }

    AppLogger.debug(
      'AppImageCacheManager: Performed cleanup. Asset cache size: ${_assetCache.length}, Widget cache size: ${_widgetCache.length}',
    );
  }

  static Map<String, int> getCacheInfo() {
    return {
      'assetCacheSize': _assetCache.length,
      'widgetCacheSize': _widgetCache.length,
      'maxCacheSize': maxCacheSize,
    };
  }
}
