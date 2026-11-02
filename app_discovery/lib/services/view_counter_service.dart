import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:shared_preferences/shared_preferences.dart';

/// Service for responsible view counting
/// Prevents spam and duplicate counting while providing meaningful metrics
class ViewCounterService {
  FirebaseFirestore? get _firestore {
    try {
      if (Firebase.apps.isNotEmpty) {
        return FirebaseFirestore.instance;
      }
    } catch (_) {}
    return null;
  }

  static const String _viewedPostsKey = 'viewed_posts';
  static const String _lastViewTimeKey = 'last_view_time';
  
  // Rate limiting: minimum time between views of the same post
  static const Duration _minViewInterval = Duration(hours: 1);
  
  // Session tracking: views within same session don't count
  static const Duration _sessionDuration = Duration(minutes: 30);

  /// Record a view for a post (if it qualifies)
  /// Returns true if view was counted, false if it was rate limited
  Future<bool> recordView(String postId) async {
    try {
      // Check if this view should be counted
      if (!await _shouldCountView(postId)) {
        print('⏭ View not counted for $postId (rate limited)');
        return false;
      }

      final firestore = _firestore;
      if (firestore != null) {
        // Increment view count in Firestore
        await firestore.collection('posts').doc(postId).update({
          'viewsCount': FieldValue.increment(1),
        });
      }

      // Record this view locally
      await _recordViewLocally(postId);

      print('✓ View counted for post: $postId');
      return true;
    } catch (e) {
      print('Notice recording view: $e');
      return false;
    }
  }

  /// Check if a view should be counted based on rate limiting rules
  Future<bool> _shouldCountView(String postId) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final lastViewTime = prefs.getInt('${_lastViewTimeKey}_$postId') ?? 0;
      final now = DateTime.now().millisecondsSinceEpoch;
      
      // Check if this post was viewed recently
      if (lastViewTime > 0) {
        final timeSinceLastView = Duration(milliseconds: now - lastViewTime);
        if (timeSinceLastView < _minViewInterval) {
          return false; // Too recent, don't count
        }
      }
      
      return true;
    } catch (e) {
      print('Notice checking view eligibility: $e');
      return true; // Default to allowing view if check fails
    }
  }

  /// Record view locally for rate limiting
  Future<void> _recordViewLocally(String postId) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final now = DateTime.now().millisecondsSinceEpoch;
      
      // Update last view time for this post
      await prefs.setInt('${_lastViewTimeKey}_$postId', now);
      
      // Add to viewed posts list (keep only recent)
      final viewedPosts = prefs.getStringList(_viewedPostsKey) ?? [];
      if (!viewedPosts.contains(postId)) {
        viewedPosts.add(postId);
        
        // Keep only last 100 viewed posts to prevent storage bloat
        if (viewedPosts.length > 100) {
          viewedPosts.removeRange(0, viewedPosts.length - 100);
        }
        
        await prefs.setStringList(_viewedPostsKey, viewedPosts);
      }
    } catch (e) {
      print('Notice recording view locally: $e');
    }
  }

  /// Get current view count for a post
  Future<int> getViewCount(String postId) async {
    try {
      final firestore = _firestore;
      if (firestore == null) return 0;

      final doc = await firestore.collection('posts').doc(postId).get();
      if (doc.exists) {
        return doc.data()?['viewsCount'] as int? ?? 0;
      }
      return 0;
    } catch (e) {
      print('Notice getting view count: $e');
      return 0;
    }
  }

  /// Clear local view history (for testing or reset)
  Future<void> clearViewHistory() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final keys = prefs.getKeys().where((key) => 
          key.startsWith(_lastViewTimeKey) || key == _viewedPostsKey).toList();
      
      for (final key in keys) {
        await prefs.remove(key);
      }
      
      print('✓ View history cleared');
    } catch (e) {
      print('Notice clearing view history: $e');
    }
  }

  /// Get statistics about view counting (for debugging)
  Future<Map<String, dynamic>> getViewStats() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final viewedPosts = prefs.getStringList(_viewedPostsKey) ?? [];
      final now = DateTime.now().millisecondsSinceEpoch;
      
      // Count recent views
      int recentViews = 0;
      for (final postId in viewedPosts) {
        final lastViewTime = prefs.getInt('${_lastViewTimeKey}_$postId') ?? 0;
        if (lastViewTime > 0) {
          final timeSinceView = Duration(milliseconds: now - lastViewTime);
          if (timeSinceView < _sessionDuration) {
            recentViews++;
          }
        }
      }
      
      return {
        'totalViewedPosts': viewedPosts.length,
        'recentViews': recentViews,
        'minViewInterval': _minViewInterval.inMinutes,
        'sessionDuration': _sessionDuration.inMinutes,
      };
    } catch (e) {
      print('Notice getting view stats: $e');
      return {};
    }
  }

  /// Validate that view counts are not tampered (basic check)
  Future<bool> validateViewCount(String postId, int expectedCount) async {
    try {
      final actualCount = await getViewCount(postId);
      final variance = (expectedCount * 0.1).round();
      final minExpected = expectedCount - variance;
      final maxExpected = expectedCount + variance;
      return actualCount >= minExpected && actualCount <= maxExpected;
    } catch (e) {
      print('Notice validating view count: $e');
      return false;
    }
  }

  /// Batch update view counts for multiple posts (admin use)
  Future<bool> batchUpdateViewCounts(Map<String, int> postViewCounts) async {
    try {
      final firestore = _firestore;
      if (firestore == null) return false;

      final batch = firestore.batch();
      for (final entry in postViewCounts.entries) {
        final postRef = firestore.collection('posts').doc(entry.key);
        batch.update(postRef, {'viewsCount': entry.value});
      }
      
      await batch.commit();
      print('✓ Batch updated ${postViewCounts.length} view counts');
      return true;
    } catch (e) {
      print('Notice in batch update: $e');
      return false;
    }
  }
}
