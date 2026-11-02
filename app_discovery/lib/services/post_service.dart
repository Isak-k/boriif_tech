import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_core/firebase_core.dart';
import '../models/post_model.dart';
import 'admin_service.dart';
import 'offline_cache_service.dart';

/// Service for handling Post data from Firestore with offline persistence
class PostService {
  FirebaseFirestore? get _firestore {
    try {
      if (Firebase.apps.isNotEmpty) {
        return FirebaseFirestore.instance;
      }
    } catch (_) {}
    return null;
  }

  /// Collection name
  static const String _postsCollection = 'posts';

  /// Fetch all published posts (resilient merge with automatic offline caching)
  Future<List<Post>> fetchPublishedPosts({
    int limit = 50,
    DocumentSnapshot? startAfter,
  }) async {
    await AdminService.hydrateFromDisk();

    try {
      final firestore = _firestore;
      if (firestore == null) {
        final cached = await OfflineCacheService.getCachedPosts();
        if (cached.isNotEmpty) {
          return cached.where((p) => p.isPublished).toList();
        }
        return AdminService.localPosts.where((p) => p.isPublished).toList();
      }

      QuerySnapshot<Map<String, dynamic>> snapshot;
      try {
        snapshot = await firestore
            .collection(_postsCollection)
            .where('isPublished', isEqualTo: true)
            .limit(limit)
            .get();
      } catch (whereErr) {
        // Fallback without where clause if index or rules issue
        snapshot = await firestore
            .collection(_postsCollection)
            .limit(limit)
            .get();
      }

      final remotePosts = snapshot.docs
          .map((doc) => Post.fromFirestore(doc))
          .where((p) => p.isPublished)
          .toList();

      final combined = <Post>[...remotePosts];
      for (final local in AdminService.localPosts) {
        if (local.isPublished && !combined.any((p) => p.id == local.id)) {
          combined.add(local);
        }
      }

      // Also check cached disk posts
      final cached = await OfflineCacheService.getCachedPosts();
      for (final c in cached) {
        if (c.isPublished && !combined.any((p) => p.id == c.id)) {
          combined.add(c);
        }
      }

      // Sort newest first
      combined.sort((a, b) => (b.publishedAt ?? b.createdAt).compareTo(a.publishedAt ?? a.createdAt));

      // Cache locally on device disk for offline use
      await OfflineCacheService.savePosts(combined);

      return combined;
    } catch (e) {
      print('Notice fetching published posts from Firestore ($e). Loading cached posts.');
      final cached = await OfflineCacheService.getCachedPosts();
      if (cached.isNotEmpty) {
        return cached.where((p) => p.isPublished).toList();
      }

      final local = AdminService.localPosts.where((p) => p.isPublished).toList();
      local.sort((a, b) => (b.publishedAt ?? b.createdAt).compareTo(a.publishedAt ?? a.createdAt));
      return local;
    }
  }

  /// Listen to published posts in real time
  Stream<List<Post>> streamPublishedPosts({int limit = 50}) {
    AdminService.hydrateFromDisk();

    try {
      final firestore = _firestore;
      if (firestore == null) {
        return Stream.fromFuture(OfflineCacheService.getCachedPosts()).map((cached) {
          final list = cached.where((p) => p.isPublished).toList();
          if (list.isNotEmpty) return list;
          return AdminService.localPosts.where((p) => p.isPublished).toList();
        });
      }

      return firestore
          .collection(_postsCollection)
          .where('isPublished', isEqualTo: true)
          .limit(limit)
          .snapshots()
          .asyncMap((snapshot) async {
            final remotePosts = snapshot.docs
                .map((doc) => Post.fromFirestore(doc))
                .toList();

            final combined = <Post>[...remotePosts];
            for (final local in AdminService.localPosts) {
              if (local.isPublished && !combined.any((p) => p.id == local.id)) {
                combined.add(local);
              }
            }

            final cached = await OfflineCacheService.getCachedPosts();
            for (final c in cached) {
              if (c.isPublished && !combined.any((p) => p.id == c.id)) {
                combined.add(c);
              }
            }

            combined.sort((a, b) => (b.publishedAt ?? b.createdAt).compareTo(a.publishedAt ?? a.createdAt));
            await OfflineCacheService.savePosts(combined);
            return combined;
          })
          .handleError((error) async {
            print('Notice streaming published posts: $error');
            final cached = await OfflineCacheService.getCachedPosts();
            if (cached.isNotEmpty) return cached.where((p) => p.isPublished).toList();
            return AdminService.localPosts.where((p) => p.isPublished).toList();
          });
    } catch (e) {
      print('Notice streaming published posts: $e');
      return Stream.value(AdminService.localPosts.where((p) => p.isPublished).toList());
    }
  }

  /// Fetch posts by category (supports 'all' for all categories)
  Future<List<Post>> fetchPostsByCategory(String categoryId, {int limit = 50}) async {
    final allPosts = await fetchPublishedPosts(limit: limit);
    if (categoryId == 'all' || categoryId.isEmpty) {
      return allPosts;
    }

    final query = categoryId.trim().toLowerCase();
    final categories = await OfflineCacheService.getCachedCategories();
    final matchedCat = categories.where((c) => c.id.toLowerCase() == query || c.name.toLowerCase() == query).firstOrNull;
    final matchedName = matchedCat?.name.toLowerCase() ?? '';

    return allPosts.where((p) {
      final pCat = p.categoryId.trim().toLowerCase();
      if (pCat == query) return true;
      if (matchedName.isNotEmpty && pCat == matchedName) return true;
      return false;
    }).toList();
  }

  /// Fetch a single post by ID
  Future<Post?> fetchPostById(String postId) async {
    await AdminService.hydrateFromDisk();

    try {
      // Check local memory cache first
      final local = AdminService.localPosts.where((p) => p.id == postId).firstOrNull;
      if (local != null) return local;

      // Check offline disk cached posts
      final cached = await OfflineCacheService.getCachedPosts();
      final cachedPost = cached.where((p) => p.id == postId).firstOrNull;
      if (cachedPost != null) return cachedPost;

      final firestore = _firestore;
      if (firestore != null) {
        final doc = await firestore.collection(_postsCollection).doc(postId).get();
        if (doc.exists) {
          final post = Post.fromFirestore(doc);
          await OfflineCacheService.upsertPost(post);
          return post;
        }
      }

      return null;
    } catch (e) {
      print('Notice fetching post: $e');
      final cached = await OfflineCacheService.getCachedPosts();
      return cached.where((p) => p.id == postId).firstOrNull ??
          AdminService.localPosts.where((p) => p.id == postId).firstOrNull;
    }
  }

  /// Fetch all posts by a specific post type (app, article, job)
  Future<List<Post>> fetchPostsByType(String postType, {int limit = 50}) async {
    final allPosts = await fetchPublishedPosts(limit: limit);
    return allPosts.where((p) => p.postType.toLowerCase() == postType.toLowerCase()).toList();
  }

  /// Increment view count for a post in Firestore, local cache, and offline storage
  Future<bool> incrementViewCount(String postId) async {
    try {
      final firestore = _firestore;
      if (firestore != null) {
        try {
          await firestore.collection(_postsCollection).doc(postId).update({
            'viewsCount': FieldValue.increment(1),
          });
        } catch (_) {}
      }

      // Update local memory
      final idx = AdminService.localPosts.indexWhere((p) => p.id == postId);
      if (idx != -1) {
        final newViews = AdminService.localPosts[idx].viewsCount + 1;
        AdminService.localPosts[idx] = AdminService.localPosts[idx].copyWith(
          viewsCount: newViews,
        );
        await OfflineCacheService.updatePostViews(postId, newViews);
      } else {
        final cached = await OfflineCacheService.getCachedPosts();
        final cIdx = cached.indexWhere((p) => p.id == postId);
        if (cIdx != -1) {
          final newViews = cached[cIdx].viewsCount + 1;
          await OfflineCacheService.updatePostViews(postId, newViews);
        }
      }

      return true;
    } catch (e) {
      print('Notice incrementing view count: $e');
      return false;
    }
  }

  /// Increment or decrement likes count for a post in Firestore, local cache, and offline storage
  Future<bool> incrementLikes(String postId, int delta) async {
    try {
      final firestore = _firestore;
      if (firestore != null) {
        try {
          await firestore.collection(_postsCollection).doc(postId).update({
            'likesCount': FieldValue.increment(delta),
          });
        } catch (_) {}
      }

      // Update local posts cache
      final idx = AdminService.localPosts.indexWhere((p) => p.id == postId);
      if (idx != -1) {
        final currentLikes = AdminService.localPosts[idx].likesCount;
        final newLikes = currentLikes + delta;
        final safeLikes = newLikes >= 0 ? newLikes : 0;
        AdminService.localPosts[idx] = AdminService.localPosts[idx].copyWith(
          likesCount: safeLikes,
        );
        await OfflineCacheService.updatePostLikes(postId, safeLikes, delta > 0);
      } else {
        final cached = await OfflineCacheService.getCachedPosts();
        final cIdx = cached.indexWhere((p) => p.id == postId);
        if (cIdx != -1) {
          final currentLikes = cached[cIdx].likesCount;
          final newLikes = currentLikes + delta;
          final safeLikes = newLikes >= 0 ? newLikes : 0;
          await OfflineCacheService.updatePostLikes(postId, safeLikes, delta > 0);
        }
      }

      return true;
    } catch (e) {
      print('Notice incrementing likes: $e');
      return false;
    }
  }

  /// Get view count for a post
  Future<int> getViewCount(String postId) async {
    try {
      final post = await fetchPostById(postId);
      return post?.viewsCount ?? 0;
    } catch (e) {
      return 0;
    }
  }

  /// Stream a single post by ID for real-time updates
  Stream<Post?> streamPostById(String postId) {
    try {
      final firestore = _firestore;
      if (firestore == null) {
        return Stream.value(AdminService.localPosts.where((p) => p.id == postId).firstOrNull);
      }

      return firestore
          .collection(_postsCollection)
          .doc(postId)
          .snapshots()
          .map((doc) {
        if (!doc.exists) {
          return AdminService.localPosts.where((p) => p.id == postId).firstOrNull;
        }
        return Post.fromFirestore(doc);
      }).handleError((error) {
        print('Notice streaming post: $error');
        return AdminService.localPosts.where((p) => p.id == postId).firstOrNull;
      });
    } catch (e) {
      print('Notice streaming post: $e');
      return Stream.value(AdminService.localPosts.where((p) => p.id == postId).firstOrNull);
    }
  }

  /// Search posts locally & resiliently by title, post code, or description
  Future<List<Post>> searchPosts(String query) async {
    final posts = await fetchPublishedPosts();
    if (query.isEmpty) return posts;

    final q = query.toLowerCase();
    return posts.where((post) {
      final matchesTitle = post.title.toLowerCase().contains(q);
      final matchesCode = post.code.toLowerCase().contains(q);
      final matchesShortDesc = post.shortDescription.toLowerCase().contains(q);
      final matchesDesc = post.description.toLowerCase().contains(q);
      return matchesTitle || matchesCode || matchesShortDesc || matchesDesc;
    }).toList();
  }
}
