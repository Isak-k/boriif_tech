import 'package:flutter_cache_manager/flutter_cache_manager.dart';
import 'dart:io';
import 'package:path_provider/path_provider.dart';

class CacheService {
  static final CacheManager _cacheManager = DefaultCacheManager();

  // Get cache size
  static Future<int> getCacheSize() async {
    try {
      final tempDir = await getTemporaryDirectory();
      final cacheDir = Directory(tempDir.path);
      
      if (!cacheDir.existsSync()) {
        return 0;
      }
      
      int totalSize = 0;
      for (final entity in cacheDir.listSync(recursive: true)) {
        if (entity is File) {
          totalSize += entity.lengthSync();
        }
      }
      return totalSize;
    } catch (e) {
      print('Error calculating cache size: $e');
      return 0;
    }
  }

  // Clear cache
  static Future<void> clearCache() async {
    try {
      await _cacheManager.emptyCache();
    } catch (e) {
      rethrow;
    }
  }

  // Format bytes to human-readable size
  static String formatBytes(int bytes) {
    if (bytes <= 0) return '0 B';
    const suffixes = ['B', 'KB', 'MB', 'GB'];
    var i = (bytes.toString().length / 3).floor();
    final divisor = _pow(1024, i);
    return '${(bytes / divisor).toStringAsFixed(2)} ${suffixes[i]}';
  }

  static double _pow(int base, int exp) {
    double result = 1;
    for (int i = 0; i < exp; i++) {
      result *= base;
    }
    return result;
  }
}
