import 'dart:convert';
import 'package:shared_preferences/shared_preferences.dart';
import '../models/post_model.dart';
import '../models/category_model.dart';

/// Service for caching posts and categories locally on user device
/// Ensures all data is automatically saved online and available offline
class OfflineCacheService {
  static const String _postsCacheKey = 'app_discovery_cached_posts';
  static const String _categoriesCacheKey = 'app_discovery_cached_categories';
  static const String _lastSyncTimeKey = 'app_discovery_last_sync_time';

  static SharedPreferences? _prefs;

  static Future<SharedPreferences> _getPrefs() async {
    _prefs ??= await SharedPreferences.getInstance();
    return _prefs!;
  }

  /// Save published posts to local storage for offline use
  static Future<void> savePosts(List<Post> posts) async {
    try {
      final prefs = await _getPrefs();
      final postListJson = posts.map((p) => p.toMap()).toList();
      await prefs.setString(_postsCacheKey, jsonEncode(postListJson));
      await prefs.setInt(_lastSyncTimeKey, DateTime.now().millisecondsSinceEpoch);
    } catch (e) {
      // ignore or log
    }
  }

  /// Retrieve cached posts from local storage when offline
  static Future<List<Post>> getCachedPosts() async {
    try {
      final prefs = await _getPrefs();
      final jsonString = prefs.getString(_postsCacheKey);
      if (jsonString == null || jsonString.isEmpty) {
        return [];
      }
      final List<dynamic> decoded = jsonDecode(jsonString);
      return decoded.map((item) => Post.fromMap(item as Map<String, dynamic>)).toList();
    } catch (e) {
      return [];
    }
  }

  /// Save categories to local storage for offline use
  static Future<void> saveCategories(List<Category> categories) async {
    try {
      final prefs = await _getPrefs();
      final catListJson = categories.map((c) => c.toMap()).toList();
      await prefs.setString(_categoriesCacheKey, jsonEncode(catListJson));
    } catch (e) {
      // ignore
    }
  }

  /// Retrieve cached categories from local storage when offline
  static Future<List<Category>> getCachedCategories() async {
    try {
      final prefs = await _getPrefs();
      final jsonString = prefs.getString(_categoriesCacheKey);
      if (jsonString == null || jsonString.isEmpty) {
        return [];
      }
      final List<dynamic> decoded = jsonDecode(jsonString);
      return decoded.map((item) => Category.fromMap(item as Map<String, dynamic>)).toList();
    } catch (e) {
      return [];
    }
  }

  /// Get last sync timestamp
  static Future<DateTime?> getLastSyncTime() async {
    try {
      final prefs = await _getPrefs();
      final ms = prefs.getInt(_lastSyncTimeKey);
      if (ms != null) {
        return DateTime.fromMillisecondsSinceEpoch(ms);
      }
    } catch (_) {}
    return null;
  }
}
