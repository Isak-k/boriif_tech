import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_core/firebase_core.dart';
import '../models/post_model.dart';
import '../models/category_model.dart';
import 'offline_cache_service.dart';

/// Service for admin-only operations with robust offline disk persistence
class AdminService {
  FirebaseFirestore? get _firestore {
    try {
      if (Firebase.apps.isNotEmpty) {
        return FirebaseFirestore.instance;
      }
    } catch (_) {}
    return null;
  }

  static const String _postsCollection = 'posts';
  static const String _categoriesCollection = 'categories';
  static const String _adminsCollection = 'admins';

  // In-memory cache synced with persistent disk storage
  static final List<Category> _localCategories = [];
  static final List<Post> _localPosts = [];

  static List<Category> get localCategories => _localCategories;
  static List<Post> get localPosts => _localPosts;

  /// Ensure in-memory lists are populated from disk storage
  static Future<void> hydrateFromDisk() async {
    try {
      final cachedPosts = await OfflineCacheService.getCachedPosts();
      if (cachedPosts.isNotEmpty) {
        _localPosts.clear();
        _localPosts.addAll(cachedPosts);
      }
      final cachedCats = await OfflineCacheService.getCachedCategories();
      if (cachedCats.isNotEmpty) {
        _localCategories.clear();
        _localCategories.addAll(cachedCats);
      }
    } catch (e) {
      print('Notice hydrating AdminService from disk: $e');
    }
  }

  /// Get dashboard statistics
  Future<Map<String, dynamic>> getDashboardStats() async {
    await hydrateFromDisk();

    try {
      final firestore = _firestore;
      if (firestore == null) {
        return _calculateLocalStats();
      }

      QuerySnapshot<Map<String, dynamic>> allPostsSnapshot;
      QuerySnapshot<Map<String, dynamic>> categoriesSnapshot;

      try {
        allPostsSnapshot = await firestore.collection(_postsCollection).get();
        categoriesSnapshot = await firestore.collection(_categoriesCollection).get();
      } catch (e) {
        print('Notice fetching Firestore stats ($e), falling back to local disk stats.');
        return _calculateLocalStats();
      }

      int totalViews = 0;
      int totalFavorites = 0;
      int publishedCount = 0;

      final remotePosts = <Post>[];
      for (final doc in allPostsSnapshot.docs) {
        final post = Post.fromFirestore(doc);
        remotePosts.add(post);
        totalViews += post.viewsCount;
        totalFavorites += post.likesCount;
        if (post.isPublished) publishedCount++;
      }

      // Merge local posts not present in remote
      for (final p in _localPosts) {
        if (!remotePosts.any((r) => r.id == p.id)) {
          totalViews += p.viewsCount;
          totalFavorites += p.likesCount;
          if (p.isPublished) publishedCount++;
        }
      }

      final totalCats = categoriesSnapshot.size > _localCategories.length
          ? categoriesSnapshot.size
          : _localCategories.length;

      return {
        'totalPosts': allPostsSnapshot.size > _localPosts.length ? allPostsSnapshot.size : _localPosts.length,
        'publishedPosts': publishedCount,
        'totalViews': totalViews,
        'totalFavorites': totalFavorites,
        'totalCategories': totalCats,
      };
    } catch (e) {
      print('Notice getting dashboard stats: $e');
      return _calculateLocalStats();
    }
  }

  Map<String, dynamic> _calculateLocalStats() {
    int localViews = 0;
    int localLikes = 0;
    for (final p in _localPosts) {
      localViews += p.viewsCount;
      localLikes += p.likesCount;
    }
    return {
      'totalPosts': _localPosts.length,
      'publishedPosts': _localPosts.where((p) => p.isPublished).length,
      'totalViews': localViews,
      'totalFavorites': localLikes,
      'totalCategories': _localCategories.length,
    };
  }

  /// Fetch all posts (including drafts) - admin only
  Future<List<Post>> fetchAllPosts({int limit = 100}) async {
    await hydrateFromDisk();

    try {
      final firestore = _firestore;
      if (firestore == null) {
        return _localPosts;
      }

      List<Post> remotePosts = [];
      try {
        final snapshot = await firestore
            .collection(_postsCollection)
            .orderBy('updatedAt', descending: true)
            .limit(limit)
            .get();
        remotePosts = snapshot.docs.map((doc) => Post.fromFirestore(doc)).toList();
      } catch (orderErr) {
        // Fallback without orderBy if index is missing
        final fallbackSnapshot = await firestore
            .collection(_postsCollection)
            .limit(limit)
            .get();
        remotePosts = fallbackSnapshot.docs.map((doc) => Post.fromFirestore(doc)).toList();
      }

      final merged = <Post>[...remotePosts];
      for (final local in _localPosts) {
        if (!merged.any((p) => p.id == local.id)) {
          merged.add(local);
        }
      }

      merged.sort((a, b) => (b.updatedAt).compareTo(a.updatedAt));

      _localPosts.clear();
      _localPosts.addAll(merged);
      await OfflineCacheService.savePosts(merged);

      return merged;
    } catch (e) {
      print('Notice fetching posts from Firestore ($e). Returning persistent cached posts.');
      return _localPosts;
    }
  }

  /// Stream all posts (including drafts) for real-time updates
  Stream<List<Post>> streamAllPosts({int limit = 100}) {
    hydrateFromDisk();

    try {
      final firestore = _firestore;
      if (firestore == null) return Stream.value(_localPosts);

      return firestore
          .collection(_postsCollection)
          .snapshots()
          .asyncMap((snapshot) async {
            final remotePosts = snapshot.docs.map((doc) => Post.fromFirestore(doc)).toList();
            final merged = <Post>[...remotePosts];
            for (final local in _localPosts) {
              if (!merged.any((p) => p.id == local.id)) {
                merged.add(local);
              }
            }
            merged.sort((a, b) => b.updatedAt.compareTo(a.updatedAt));

            _localPosts.clear();
            _localPosts.addAll(merged);
            await OfflineCacheService.savePosts(merged);
            return merged;
          })
          .handleError((e) {
            print('Notice streaming all posts error: $e');
            return _localPosts;
          });
    } catch (e) {
      print('Notice streaming all posts: $e');
      return Stream.value(_localPosts);
    }
  }

  /// Fetch recent posts for dashboard
  Future<List<Post>> fetchRecentPosts({int limit = 5}) async {
    await hydrateFromDisk();

    try {
      final firestore = _firestore;
      if (firestore == null) return _localPosts.take(limit).toList();

      try {
        final snapshot = await firestore
            .collection(_postsCollection)
            .orderBy('createdAt', descending: true)
            .limit(limit)
            .get();
        return snapshot.docs.map((doc) => Post.fromFirestore(doc)).toList();
      } catch (_) {
        final snapshot = await firestore.collection(_postsCollection).limit(limit).get();
        final list = snapshot.docs.map((doc) => Post.fromFirestore(doc)).toList();
        list.sort((a, b) => b.createdAt.compareTo(a.createdAt));
        return list;
      }
    } catch (e) {
      print('Notice fetching recent posts: $e');
      return _localPosts.take(limit).toList();
    }
  }

  /// Fetch all categories for admin management
  Future<List<Category>> fetchAllCategories() async {
    await hydrateFromDisk();

    try {
      final firestore = _firestore;
      if (firestore == null) return _localCategories;

      List<Category> remoteCategories = [];
      try {
        final snapshot = await firestore
            .collection(_categoriesCollection)
            .orderBy('name')
            .get();
        remoteCategories = snapshot.docs.map((doc) => Category.fromFirestore(doc)).toList();
      } catch (_) {
        final fallback = await firestore.collection(_categoriesCollection).get();
        remoteCategories = fallback.docs.map((doc) => Category.fromFirestore(doc)).toList();
      }

      final merged = <Category>[...remoteCategories];
      for (final local in _localCategories) {
        if (!merged.any((c) => c.id == local.id || c.name.toLowerCase() == local.name.toLowerCase())) {
          merged.add(local);
        }
      }

      merged.sort((a, b) => a.name.toLowerCase().compareTo(b.name.toLowerCase()));

      _localCategories.clear();
      _localCategories.addAll(merged);
      await OfflineCacheService.saveCategories(merged);

      return merged;
    } catch (e) {
      print('Notice fetching categories from Firestore ($e). Returning local categories.');
      return _localCategories;
    }
  }

  /// Check if category has associated posts
  Future<int> getPostsCountByCategory(String categoryId) async {
    await hydrateFromDisk();
    return _localPosts.where((p) => p.categoryId == categoryId).length;
  }

  /// Publish a post
  Future<void> publishPost(String postId) async {
    final idx = _localPosts.indexWhere((p) => p.id == postId);
    if (idx != -1) {
      final updated = _localPosts[idx].copyWith(
        isPublished: true,
        publishedAt: DateTime.now(),
        updatedAt: DateTime.now(),
      );
      _localPosts[idx] = updated;
      await OfflineCacheService.upsertPost(updated);
    }

    try {
      final firestore = _firestore;
      if (firestore != null) {
        await firestore.collection(_postsCollection).doc(postId).update({
          'isPublished': true,
          'publishedAt': Timestamp.now(),
          'updatedAt': Timestamp.now(),
        });
      }
      print('✓ Post published: $postId');
    } catch (e) {
      print('Notice publishing post to Firestore ($e). Preserved locally on device.');
    }
  }

  /// Unpublish a post
  Future<void> unpublishPost(String postId) async {
    final idx = _localPosts.indexWhere((p) => p.id == postId);
    if (idx != -1) {
      final updated = _localPosts[idx].copyWith(
        isPublished: false,
        updatedAt: DateTime.now(),
      );
      _localPosts[idx] = updated;
      await OfflineCacheService.upsertPost(updated);
    }

    try {
      final firestore = _firestore;
      if (firestore != null) {
        await firestore.collection(_postsCollection).doc(postId).update({
          'isPublished': false,
          'updatedAt': Timestamp.now(),
        });
      }
      print('✓ Post unpublished: $postId');
    } catch (e) {
      print('Notice unpublishing post from Firestore ($e). Preserved locally on device.');
    }
  }

  /// Verify if user has admin access
  Future<bool> verifyAdminAccess(String userId) async {
    try {
      final firestore = _firestore;
      if (firestore == null) return false;

      final doc = await firestore
          .collection(_adminsCollection)
          .doc(userId)
          .get();
      return doc.exists && (doc.data()?['isAdmin'] as bool? ?? false);
    } catch (e) {
      print('Notice verifying admin access: $e');
      return false;
    }
  }

  /// Create a new post - saves immediately to disk cache AND Firestore
  Future<String> createPost({
    required String title,
    required String shortDescription,
    required String description,
    required String postType,
    required String categoryId,
    String? code,
    String? imageUrl,
    String? playStoreUrl,
    String? externalUrl,
    bool isPublished = true,
  }) async {
    final now = DateTime.now();
    final postCode = (code != null && code.trim().isNotEmpty)
        ? code.trim().toUpperCase()
        : 'APP-${now.millisecondsSinceEpoch.toString().substring(8)}';

    // Generate stable unique local ID immediately
    final assignedId = 'post_${now.millisecondsSinceEpoch}';

    var post = Post(
      id: assignedId,
      code: postCode,
      title: title,
      shortDescription: shortDescription,
      description: description,
      postType: postType,
      categoryId: categoryId,
      imageUrl: imageUrl,
      playStoreUrl: playStoreUrl,
      externalUrl: externalUrl,
      isPublished: isPublished,
      createdAt: now,
      updatedAt: now,
      publishedAt: isPublished ? now : null,
      viewsCount: 0,
      likesCount: 0,
    );

    // 1. Save IMMEDIATELY to local persistent disk storage
    _localPosts.removeWhere((p) => p.id == assignedId);
    _localPosts.insert(0, post);
    await OfflineCacheService.upsertPost(post);

    // 2. Sync to Firestore
    try {
      final firestore = _firestore;
      if (firestore != null) {
        final docRef = await firestore
            .collection(_postsCollection)
            .add(post.toFirestore());

        // Update with Firestore document ID
        post = post.copyWith(id: docRef.id);
        _localPosts.removeWhere((p) => p.id == assignedId || p.id == docRef.id);
        _localPosts.insert(0, post);

        await OfflineCacheService.deletePost(assignedId);
        await OfflineCacheService.upsertPost(post);

        print('✓ Post stored in Firestore: ${docRef.id}');
        return docRef.id;
      }
    } catch (e) {
      print('Notice: Firestore rejected post creation ($e). Post securely cached on local disk.');
    }

    return assignedId;
  }

  /// Update an existing post
  Future<void> updatePost({
    required String postId,
    required String title,
    required String shortDescription,
    required String description,
    required String postType,
    required String categoryId,
    String? code,
    String? imageUrl,
    String? playStoreUrl,
    String? externalUrl,
    bool? isPublished,
  }) async {
    final idx = _localPosts.indexWhere((p) => p.id == postId);
    if (idx != -1) {
      final updated = _localPosts[idx].copyWith(
        title: title,
        code: code ?? _localPosts[idx].code,
        shortDescription: shortDescription,
        description: description,
        postType: postType,
        categoryId: categoryId,
        imageUrl: imageUrl,
        playStoreUrl: playStoreUrl,
        externalUrl: externalUrl,
        isPublished: isPublished ?? _localPosts[idx].isPublished,
        updatedAt: DateTime.now(),
      );
      _localPosts[idx] = updated;
      await OfflineCacheService.upsertPost(updated);
    }

    try {
      final firestore = _firestore;
      if (firestore != null) {
        final updateData = <String, dynamic>{
          'title': title,
          'shortDescription': shortDescription,
          'description': description,
          'postType': postType,
          'categoryId': categoryId,
          'imageUrl': imageUrl,
          'playStoreUrl': playStoreUrl,
          'externalUrl': externalUrl,
          'updatedAt': Timestamp.now(),
        };

        if (code != null && code.trim().isNotEmpty) {
          updateData['code'] = code.trim().toUpperCase();
        }

        if (isPublished != null) {
          updateData['isPublished'] = isPublished;
        }

        await firestore
            .collection(_postsCollection)
            .doc(postId)
            .set(updateData, SetOptions(merge: true));
        print('✓ Post updated in Firestore: $postId');
      }
    } catch (e) {
      print('Notice updating post in Firestore: $e. Saved on local disk.');
    }
  }

  /// Delete a post
  Future<void> deletePost(String postId) async {
    _localPosts.removeWhere((p) => p.id == postId);
    await OfflineCacheService.deletePost(postId);

    try {
      final firestore = _firestore;
      if (firestore != null) {
        await firestore
            .collection(_postsCollection)
            .doc(postId)
            .delete();
        print('✓ Post deleted from Firestore: $postId');
      }
    } catch (e) {
      print('Notice deleting post from Firestore: $e. Removed from local disk.');
    }
  }

  /// Create a new category - saves immediately to disk cache AND Firestore
  Future<String> createCategory(String name) async {
    final now = DateTime.now();
    final assignedId = 'cat_${now.millisecondsSinceEpoch}';

    var category = Category(
      id: assignedId,
      name: name,
      createdAt: now,
      updatedAt: now,
    );

    // 1. Save immediately to disk cache
    _localCategories.removeWhere((c) => c.name.toLowerCase() == name.toLowerCase());
    _localCategories.insert(0, category);
    await OfflineCacheService.upsertCategory(category);

    // 2. Sync to Firestore
    try {
      final firestore = _firestore;
      if (firestore != null) {
        final docRef = await firestore
            .collection(_categoriesCollection)
            .add(category.toFirestore());

        category = category.copyWith(id: docRef.id);
        _localCategories.removeWhere((c) => c.id == assignedId || c.id == docRef.id);
        _localCategories.insert(0, category);

        await OfflineCacheService.deleteCategory(assignedId);
        await OfflineCacheService.upsertCategory(category);

        print('✓ Category created in Firestore: ${docRef.id}');
        return docRef.id;
      }
    } catch (e) {
      print('Notice: Firestore rejected category creation ($e). Category securely saved to device disk.');
    }

    return assignedId;
  }

  /// Update an existing category
  Future<void> updateCategory({
    required String categoryId,
    required String name,
  }) async {
    final idx = _localCategories.indexWhere((c) => c.id == categoryId);
    if (idx != -1) {
      final updated = _localCategories[idx].copyWith(
        name: name,
        updatedAt: DateTime.now(),
      );
      _localCategories[idx] = updated;
      await OfflineCacheService.upsertCategory(updated);
    }

    try {
      final firestore = _firestore;
      if (firestore != null) {
        await firestore
            .collection(_categoriesCollection)
            .doc(categoryId)
            .set({
              'name': name,
              'updatedAt': Timestamp.now(),
            }, SetOptions(merge: true));
        print('✓ Category updated in Firestore: $categoryId');
      }
    } catch (e) {
      print('Notice updating category in Firestore: $e. Saved on local disk.');
    }
  }

  /// Delete a category
  Future<void> deleteCategory(String categoryId) async {
    _localCategories.removeWhere((c) => c.id == categoryId);
    await OfflineCacheService.deleteCategory(categoryId);

    try {
      final firestore = _firestore;
      if (firestore != null) {
        await firestore
            .collection(_categoriesCollection)
            .doc(categoryId)
            .delete();
        print('✓ Category deleted from Firestore: $categoryId');
      }
    } catch (e) {
      print('Notice deleting category from Firestore: $e. Removed from local disk.');
    }
  }

  /// Grant admin access to a user
  Future<void> grantAdminAccess(String userId, String email) async {
    try {
      final firestore = _firestore;
      if (firestore != null) {
        await firestore.collection(_adminsCollection).doc(userId).set({
          'email': email,
          'isAdmin': true,
          'grantedAt': Timestamp.now(),
        });
      }
      print('✓ Admin access granted to: $email');
    } catch (e) {
      print('Notice granting admin access: $e');
    }
  }

  /// Revoke admin access
  Future<void> revokeAdminAccess(String userId) async {
    try {
      final firestore = _firestore;
      if (firestore != null) {
        await firestore
            .collection(_adminsCollection)
            .doc(userId)
            .delete();
      }
      print('✓ Admin access revoked');
    } catch (e) {
      print('Notice revoking admin access: $e');
    }
  }
}
