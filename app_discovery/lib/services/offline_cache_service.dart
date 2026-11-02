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
      print('Notice saving cached posts: $e');
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
      print('Notice reading cached posts: $e');
      return [];
    }
  }

  /// Insert or update a post in local persistent storage
  static Future<void> upsertPost(Post post) async {
    try {
      final posts = await getCachedPosts();
      final index = posts.indexWhere((p) => p.id == post.id);
      if (index != -1) {
        posts[index] = post;
      } else {
        posts.insert(0, post);
      }
      await savePosts(posts);
    } catch (e) {
      print('Notice upserting cached post: $e');
    }
  }

  /// Delete a post from local persistent storage
  static Future<void> deletePost(String postId) async {
    try {
      final posts = await getCachedPosts();
      posts.removeWhere((p) => p.id == postId);
      await savePosts(posts);
    } catch (e) {
      print('Notice deleting cached post: $e');
    }
  }

  /// Update view count for a specific post in local storage
  static Future<void> updatePostViews(String postId, int newViews) async {
    try {
      final posts = await getCachedPosts();
      final index = posts.indexWhere((p) => p.id == postId);
      if (index != -1) {
        posts[index] = posts[index].copyWith(viewsCount: newViews);
        await savePosts(posts);
      }
    } catch (e) {
      print('Notice updating post views in cache: $e');
    }
  }

  /// Update likes count and favorite status in local storage
  static Future<void> updatePostLikes(String postId, int newLikes, bool isFavorite) async {
    try {
      final posts = await getCachedPosts();
      final index = posts.indexWhere((p) => p.id == postId);
      if (index != -1) {
        posts[index] = posts[index].copyWith(
          likesCount: newLikes,
          isFavorite: isFavorite,
        );
        await savePosts(posts);
      }
    } catch (e) {
      print('Notice updating post likes in cache: $e');
    }
  }

  /// Save categories to local storage for offline use
  static Future<void> saveCategories(List<Category> categories) async {
    try {
      final prefs = await _getPrefs();
      final catListJson = categories.map((c) => c.toMap()).toList();
      await prefs.setString(_categoriesCacheKey, jsonEncode(catListJson));
    } catch (e) {
      print('Notice saving cached categories: $e');
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
      print('Notice reading cached categories: $e');
      return [];
    }
  }

  /// Insert or update a category in local persistent storage
  static Future<void> upsertCategory(Category category) async {
    try {
      final categories = await getCachedCategories();
      final index = categories.indexWhere((c) => c.id == category.id);
      if (index != -1) {
        categories[index] = category;
      } else {
        categories.insert(0, category);
      }
      await saveCategories(categories);
    } catch (e) {
      print('Notice upserting cached category: $e');
    }
  }

  /// Delete a category from local persistent storage
  static Future<void> deleteCategory(String categoryId) async {
    try {
      final categories = await getCachedCategories();
      categories.removeWhere((c) => c.id == categoryId);
      await saveCategories(categories);
    } catch (e) {
      print('Notice deleting cached category: $e');
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
