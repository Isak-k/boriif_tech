import 'package:shared_preferences/shared_preferences.dart';
import 'dart:convert';

/// Service for persisting favorites locally
/// Handles storage for anonymous users across app restarts
class FavoritesService {
  static const String _favoritesKey = 'app_discovery_favorites';
  late SharedPreferences _prefs;
  bool _initialized = false;

  /// Initialize the service
  Future<void> init() async {
    if (_initialized) return;
    _prefs = await SharedPreferences.getInstance();
    _initialized = true;
    print('✓ Favorites service initialized');
  }

  /// Ensure service is initialized
  Future<void> _ensureInitialized() async {
    if (!_initialized) {
      await init();
    }
  }

  /// Add post to favorites
  Future<bool> addFavorite(String postId) async {
    try {
      await _ensureInitialized();
      final favorites = await getFavorites();
      if (!favorites.contains(postId)) {
        favorites.add(postId);
        await _saveFavorites(favorites);
        print('✓ Added favorite: $postId');
        return true;
      }
      return false;
    } catch (e) {
      print('✗ Error adding favorite: $e');
      return false;
    }
  }

  /// Remove post from favorites
  Future<bool> removeFavorite(String postId) async {
    try {
      await _ensureInitialized();
      final favorites = await getFavorites();
      if (favorites.remove(postId)) {
        await _saveFavorites(favorites);
        print('✓ Removed favorite: $postId');
        return true;
      }
      return false;
    } catch (e) {
      print('✗ Error removing favorite: $e');
      return false;
    }
  }

  /// Get all favorite post IDs
  Future<List<String>> getFavorites() async {
    try {
      await _ensureInitialized();
      final json = _prefs.getString(_favoritesKey);
      if (json == null) return [];
      final list = jsonDecode(json) as List;
      return list.cast<String>();
    } catch (e) {
      print('✗ Error retrieving favorites: $e');
      return [];
    }
  }

  /// Check if a post is favorited
  Future<bool> isFavorite(String postId) async {
    try {
      await _ensureInitialized();
      final favorites = await getFavorites();
      return favorites.contains(postId);
    } catch (e) {
      print('✗ Error checking favorite status: $e');
      return false;
    }
  }

  /// Clear all favorites
  Future<void> clearFavorites() async {
    try {
      await _ensureInitialized();
      await _prefs.remove(_favoritesKey);
      print('✓ Favorites cleared');
    } catch (e) {
      print('✗ Error clearing favorites: $e');
    }
  }

  /// Save favorites to local storage
  Future<void> _saveFavorites(List<String> favorites) async {
    try {
      final json = jsonEncode(favorites);
      await _prefs.setString(_favoritesKey, json);
    } catch (e) {
      print('✗ Error saving favorites: $e');
    }
  }

  /// Remove favorites for deleted posts
  /// Call this after fetching posts to clean up references to deleted posts
  Future<void> cleanupDeletedPosts(List<String> existingPostIds) async {
    try {
      await _ensureInitialized();
      final favorites = await getFavorites();
      final before = favorites.length;
      
      // Remove posts that no longer exist
      favorites.retainWhere((postId) => existingPostIds.contains(postId));
      
      if (favorites.length != before) {
        await _saveFavorites(favorites);
        print('✓ Cleaned up ${before - favorites.length} deleted favorites');
      }
    } catch (e) {
      print('✗ Error cleaning up deleted posts: $e');
    }
  }

  /// Remove unpublished posts from favorites
  /// Returns list of removed post IDs
  Future<List<String>> removeUnpublishedPosts(List<String> unpublishedPostIds) async {
    try {
      await _ensureInitialized();
      final favorites = await getFavorites();
      final removed = <String>[];

      for (final postId in unpublishedPostIds) {
        if (favorites.remove(postId)) {
          removed.add(postId);
        }
      }

      if (removed.isNotEmpty) {
        await _saveFavorites(favorites);
        print('✓ Removed ${removed.length} unpublished favorites');
      }

      return removed;
    } catch (e) {
      print('✗ Error removing unpublished posts: $e');
      return [];
    }
  }

  /// Get count of favorites
  Future<int> getFavoritesCount() async {
    try {
      await _ensureInitialized();
      final favorites = await getFavorites();
      return favorites.length;
    } catch (e) {
      print('✗ Error getting favorites count: $e');
      return 0;
    }
  }
}
