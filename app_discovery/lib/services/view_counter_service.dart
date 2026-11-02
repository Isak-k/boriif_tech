import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'offline_cache_service.dart';
import 'admin_service.dart';

/// Service for reliable, real-time view counting
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
  
  // Rate limiting debounce: 3 seconds to avoid duplicate clicks while allowing genuine views
  static const Duration _minViewInterval = Duration(seconds: 3);

  /// Record a view for a post in real-time
  /// Returns true if view was counted and applied
  Future<bool> recordView(String postId) async {
    try {
      // Check if this view should be counted
      if (!await _shouldCountView(postId)) {
        return false;
      }

      // Record this view timestamp locally first
      await _recordViewLocally(postId);

      // Increment in Firestore if available
      try {
        final firestore = _firestore;
        if (firestore != null) {
          await firestore.collection('posts').doc(postId).update({
            'viewsCount': FieldValue.increment(1),
          });
        }
      } catch (e) {
        print('Notice updating view count in Firestore: $e. Handled locally.');
      }

      // Update in local in-memory posts
      final idx = AdminService.localPosts.indexWhere((p) => p.id == postId);
      if (idx != -1) {
        final updatedViews = AdminService.localPosts[idx].viewsCount + 1;
        AdminService.localPosts[idx] = AdminService.localPosts[idx].copyWith(
          viewsCount: updatedViews,
        );
        await OfflineCacheService.updatePostViews(postId, updatedViews);
      } else {
        // Fetch from offline cache and update
        final cached = await OfflineCacheService.getCachedPosts();
        final cIdx = cached.indexWhere((p) => p.id == postId);
        if (cIdx != -1) {
          final updatedViews = cached[cIdx].viewsCount + 1;
          await OfflineCacheService.updatePostViews(postId, updatedViews);
        }
      }

      print('✓ Real-time view counted for post: $postId');
      return true;
    } catch (e) {
      print('Notice recording view: $e');
      return false;
    }
  }

  /// Check if a view should be counted
  Future<bool> _shouldCountView(String postId) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final lastViewTime = prefs.getInt('${_lastViewTimeKey}_$postId') ?? 0;
      final now = DateTime.now().millisecondsSinceEpoch;
      
      if (lastViewTime > 0) {
        final timeSinceLastView = Duration(milliseconds: now - lastViewTime);
        if (timeSinceLastView < _minViewInterval) {
          return false; // Debounce rapid taps within 3 seconds
        }
      }
      
      return true;
    } catch (e) {
      return true;
    }
  }

  /// Record view timestamp locally
  Future<void> _recordViewLocally(String postId) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final now = DateTime.now().millisecondsSinceEpoch;
      await prefs.setInt('${_lastViewTimeKey}_$postId', now);
      
      final viewedPosts = prefs.getStringList(_viewedPostsKey) ?? [];
      if (!viewedPosts.contains(postId)) {
        viewedPosts.add(postId);
        if (viewedPosts.length > 200) {
          viewedPosts.removeRange(0, viewedPosts.length - 200);
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
      if (firestore != null) {
        final doc = await firestore.collection('posts').doc(postId).get();
        if (doc.exists) {
          return doc.data()?['viewsCount'] as int? ?? 0;
        }
      }
      final local = AdminService.localPosts.where((p) => p.id == postId).firstOrNull;
      if (local != null) return local.viewsCount;

      final cached = await OfflineCacheService.getCachedPosts();
      return cached.where((p) => p.id == postId).firstOrNull?.viewsCount ?? 0;
    } catch (e) {
      return 0;
    }
  }
}
