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

  /// Fetch all published posts (paginated, resilient merge with automatic offline caching)
  Future<List<Post>> fetchPublishedPosts({
    int limit = 50,
    DocumentSnapshot? startAfter,
  }) async {
    try {
      final firestore = _firestore;
      if (firestore == null) {
        final cached = await OfflineCacheService.getCachedPosts();
        if (cached.isNotEmpty) return cached;
        return AdminService.localPosts.where((p) => p.isPublished).toList();
      }

      final snapshot = await firestore
          .collection(_postsCollection)
          .where('isPublished', isEqualTo: true)
          .limit(limit)
          .get();

      final remotePosts = snapshot.docs
          .map((doc) => Post.fromFirestore(doc))
          .toList();

      final combined = <Post>[...remotePosts];
      for (final local in AdminService.localPosts) {
        if (local.isPublished && !combined.any((p) => p.id == local.id)) {
          combined.add(local);
        }
      }

      // Sort newest first by publishedAt or createdAt
      combined.sort((a, b) => (b.publishedAt ?? b.createdAt).compareTo(a.publishedAt ?? a.createdAt));

      // Cache locally on device for offline use
      await OfflineCacheService.savePosts(combined);

      return combined;
    } catch (e) {
      print('Notice fetching published posts from Firestore ($e). Loading cached posts.');
      final cached = await OfflineCacheService.getCachedPosts();
      if (cached.isNotEmpty) return cached;

      final local = AdminService.localPosts.where((p) => p.isPublished).toList();
      local.sort((a, b) => (b.publishedAt ?? b.createdAt).compareTo(a.publishedAt ?? a.createdAt));
      return local;
    }
  }

  /// Listen to published posts in real time
  Stream<List<Post>> streamPublishedPosts({int limit = 50}) {
    try {
      final firestore = _firestore;
      if (firestore == null) {
        return Stream.fromFuture(OfflineCacheService.getCachedPosts()).asyncMap((cached) {
          if (cached.isNotEmpty) return cached;
          final local = AdminService.localPosts.where((p) => p.isPublished).toList();
          local.sort((a, b) => (b.publishedAt ?? b.createdAt).compareTo(a.publishedAt ?? a.createdAt));
          return local;
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

            combined.sort((a, b) => (b.publishedAt ?? b.createdAt).compareTo(a.publishedAt ?? a.createdAt));
            // Automatically save to local offline cache
            await OfflineCacheService.savePosts(combined);
            return combined;
          })
          .handleError((error) async {
            print('Notice streaming published posts: $error');
            final cached = await OfflineCacheService.getCachedPosts();
            if (cached.isNotEmpty) return cached;
            final local = AdminService.localPosts.where((p) => p.isPublished).toList();
            local.sort((a, b) => (b.publishedAt ?? b.createdAt).compareTo(a.publishedAt ?? a.createdAt));
            return local;
          });
    } catch (e) {
      print('Notice streaming published posts: $e');
      final local = AdminService.localPosts.where((p) => p.isPublished).toList();
      local.sort((a, b) => (b.publishedAt ?? b.createdAt).compareTo(a.publishedAt ?? a.createdAt));
      return Stream.value(local);
    }
  }

  /// Fetch posts by category (supports 'all' for all categories)
  Future<List<Post>> fetchPostsByCategory(String categoryId, {int limit = 50}) async {
    if (categoryId == 'all' || categoryId.isEmpty) {
      return fetchPublishedPosts(limit: limit);
    }

    try {
      final firestore = _firestore;
      if (firestore == null) {
        final cached = await OfflineCacheService.getCachedPosts();
        if (cached.isNotEmpty) {
          return cached.where((p) => p.categoryId == categoryId).toList();
        }
        final local = AdminService.localPosts
            .where((p) => p.categoryId == categoryId && p.isPublished)
            .toList();
        local.sort((a, b) => (b.publishedAt ?? b.createdAt).compareTo(a.publishedAt ?? a.createdAt));
        return local;
      }

      final snapshot = await firestore
          .collection(_postsCollection)
          .where('categoryId', isEqualTo: categoryId)
          .where('isPublished', isEqualTo: true)
          .limit(limit)
          .get();

      final remotePosts = snapshot.docs
          .map((doc) => Post.fromFirestore(doc))
          .toList();

      final combined = <Post>[...remotePosts];
      for (final local in AdminService.localPosts) {
        if (local.categoryId == categoryId && local.isPublished && !combined.any((p) => p.id == local.id)) {
          combined.add(local);
        }
      }

      combined.sort((a, b) => (b.publishedAt ?? b.createdAt).compareTo(a.publishedAt ?? a.createdAt));
      return combined;
    } catch (e) {
      print('Notice fetching posts by category ($e). Checking offline cache.');
      final cached = await OfflineCacheService.getCachedPosts();
      if (cached.isNotEmpty) {
        return cached.where((p) => p.categoryId == categoryId).toList();
      }
      final local = AdminService.localPosts
          .where((p) => p.categoryId == categoryId && p.isPublished)
          .toList();
      local.sort((a, b) => (b.publishedAt ?? b.createdAt).compareTo(a.publishedAt ?? a.createdAt));
      return local;
    }
  }

  /// Fetch a single post by ID
  Future<Post?> fetchPostById(String postId) async {
    try {
      // Check local cache first
      final local = AdminService.localPosts.where((p) => p.id == postId).firstOrNull;
      if (local != null) return local;

      final firestore = _firestore;
      if (firestore != null) {
        final doc = await firestore.collection(_postsCollection).doc(postId).get();
        if (doc.exists) {
          return Post.fromFirestore(doc);
        }
      }

      // Check offline cached posts
      final cached = await OfflineCacheService.getCachedPosts();
      return cached.where((p) => p.id == postId).firstOrNull;
    } catch (e) {
      print('Notice fetching post: $e');
      final cached = await OfflineCacheService.getCachedPosts();
      return cached.where((p) => p.id == postId).firstOrNull ??
          AdminService.localPosts.where((p) => p.id == postId).firstOrNull;
    }
  }

  /// Fetch all posts by a specific post type (app, article, job)
  Future<List<Post>> fetchPostsByType(String postType, {int limit = 50}) async {
    try {
      final firestore = _firestore;
      if (firestore == null) {
        final cached = await OfflineCacheService.getCachedPosts();
        if (cached.isNotEmpty) {
          return cached.where((p) => p.postType == postType).toList();
        }
        return AdminService.localPosts
            .where((p) => p.postType == postType && p.isPublished)
            .toList();
      }

      final snapshot = await firestore
          .collection(_postsCollection)
          .where('postType', isEqualTo: postType)
          .where('isPublished', isEqualTo: true)
          .limit(limit)
          .get();

      final remotePosts = snapshot.docs
          .map((doc) => Post.fromFirestore(doc))
          .toList();

      final combined = <Post>[...remotePosts];
      for (final local in AdminService.localPosts) {
        if (local.postType == postType && local.isPublished && !combined.any((p) => p.id == local.id)) {
          combined.add(local);
        }
      }

      combined.sort((a, b) => (b.publishedAt ?? b.createdAt).compareTo(a.publishedAt ?? a.createdAt));
      return combined;
    } catch (e) {
      print('Notice fetching posts by type: $e');
      final cached = await OfflineCacheService.getCachedPosts();
      if (cached.isNotEmpty) {
        return cached.where((p) => p.postType == postType).toList();
      }
      return AdminService.localPosts
          .where((p) => p.postType == postType && p.isPublished)
          .toList();
    }
  }

  /// Increment view count for a post in Firestore, local cache, and offline storage
  Future<bool> incrementViewCount(String postId) async {
    try {
      final firestore = _firestore;
      if (firestore != null) {
        await firestore.collection(_postsCollection).doc(postId).update({
          'viewsCount': FieldValue.increment(1),
        });
      }

      // Update local posts cache
      final idx = AdminService.localPosts.indexWhere((p) => p.id == postId);
      if (idx != -1) {
        AdminService.localPosts[idx] = AdminService.localPosts[idx].copyWith(
          viewsCount: AdminService.localPosts[idx].viewsCount + 1,
        );
      }

      // Update offline cache
      final cached = await OfflineCacheService.getCachedPosts();
      final cIdx = cached.indexWhere((p) => p.id == postId);
      if (cIdx != -1) {
        cached[cIdx] = cached[cIdx].copyWith(viewsCount: cached[cIdx].viewsCount + 1);
        await OfflineCacheService.savePosts(cached);
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
        await firestore.collection(_postsCollection).doc(postId).update({
          'likesCount': FieldValue.increment(delta),
        });
      }

      // Update local posts cache as well
      final idx = AdminService.localPosts.indexWhere((p) => p.id == postId);
      if (idx != -1) {
        final currentLikes = AdminService.localPosts[idx].likesCount;
        final newLikes = currentLikes + delta;
        AdminService.localPosts[idx] = AdminService.localPosts[idx].copyWith(
          likesCount: newLikes >= 0 ? newLikes : 0,
        );
      }

      // Update offline cache
      final cached = await OfflineCacheService.getCachedPosts();
      final cIdx = cached.indexWhere((p) => p.id == postId);
      if (cIdx != -1) {
        final currentLikes = cached[cIdx].likesCount;
        final newLikes = currentLikes + delta;
        cached[cIdx] = cached[cIdx].copyWith(likesCount: newLikes >= 0 ? newLikes : 0);
        await OfflineCacheService.savePosts(cached);
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

  /// Create a new post (admin only)
  Future<String> createPost(Post post) async {
    try {
      final firestore = _firestore;
      if (firestore == null) {
        AdminService.localPosts.insert(0, post);
        return post.id;
      }

      final docRef = await firestore.collection(_postsCollection).add(
        post.toFirestore(),
      );
      final created = post.copyWith(id: docRef.id);
      AdminService.localPosts.insert(0, created);
      print('✓ Post created: ${docRef.id}');
      return docRef.id;
    } catch (e) {
      print('Notice creating post in Firestore ($e). Storing locally.');
      AdminService.localPosts.insert(0, post);
      return post.id;
    }
  }

  /// Update a post (admin only)
  Future<void> updatePost(String postId, Post post) async {
    try {
      final firestore = _firestore;
      if (firestore != null) {
        await firestore.collection(_postsCollection).doc(postId).update(
          post.toFirestore(),
        );
      }
      final idx = AdminService.localPosts.indexWhere((p) => p.id == postId);
      if (idx != -1) {
        AdminService.localPosts[idx] = post;
      }
      print('✓ Post updated: $postId');
    } catch (e) {
      print('Notice updating post: $e');
    }
  }

  /// Delete a post (admin only)
  Future<void> deletePost(String postId) async {
    try {
      final firestore = _firestore;
      if (firestore != null) {
        await firestore.collection(_postsCollection).doc(postId).delete();
      }
      AdminService.localPosts.removeWhere((p) => p.id == postId);
      print('✓ Post deleted: $postId');
    } catch (e) {
      print('Notice deleting post: $e');
      AdminService.localPosts.removeWhere((p) => p.id == postId);
    }
  }

  /// Search posts by title, code, or description
  Future<List<Post>> searchPosts(String query) async {
    try {
      final all = await fetchPublishedPosts();
      final q = query.trim().toLowerCase();
      if (q.isEmpty) return all;

      return all
          .where((post) =>
              post.title.toLowerCase().contains(q) ||
              post.code.toLowerCase().contains(q) ||
              post.description.toLowerCase().contains(q) ||
              post.shortDescription.toLowerCase().contains(q))
          .toList();
    } catch (e) {
      print('Notice searching posts: $e');
      return [];
    }
  }
}
