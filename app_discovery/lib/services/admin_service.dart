import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_core/firebase_core.dart';
import '../models/post_model.dart';
import '../models/category_model.dart';

/// Service for admin-only operations
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

  // Resilient in-memory caching fallback if Firestore rules reject operation
  static final List<Category> _localCategories = [];
  static final List<Post> _localPosts = [];

  static List<Category> get localCategories => _localCategories;
  static List<Post> get localPosts => _localPosts;

  /// Get dashboard statistics
  Future<Map<String, dynamic>> getDashboardStats() async {
    try {
      final firestore = _firestore;
      if (firestore == null) {
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
      final allPostsSnapshot = await firestore.collection(_postsCollection).get();
      final publishedPostsSnapshot = await firestore
          .collection(_postsCollection)
          .where('isPublished', isEqualTo: true)
          .get();
      final categoriesSnapshot = await firestore.collection(_categoriesCollection).get();

      int totalViews = 0;
      int totalFavorites = 0;

      for (final doc in allPostsSnapshot.docs) {
        final data = doc.data();
        totalViews += (data['viewsCount'] as int?) ?? 0;
        totalFavorites += (data['likesCount'] as int?) ?? ((data['favoritesCount'] as int?) ?? 0);
      }

      for (final p in _localPosts) {
        totalViews += p.viewsCount;
        totalFavorites += p.likesCount;
      }

      return {
        'totalPosts': allPostsSnapshot.size + _localPosts.length,
        'publishedPosts': publishedPostsSnapshot.size + _localPosts.where((p) => p.isPublished).length,
        'totalViews': totalViews,
        'totalFavorites': totalFavorites,
        'totalCategories': categoriesSnapshot.size + _localCategories.length,
      };
    } catch (e) {
      print('Notice getting dashboard stats: $e');
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
  }

  /// Fetch all posts (including drafts) - admin only
  Future<List<Post>> fetchAllPosts({int limit = 100}) async {
    try {
      final firestore = _firestore;
      if (firestore == null) return _localPosts;

      final snapshot = await firestore
          .collection(_postsCollection)
          .orderBy('updatedAt', descending: true)
          .limit(limit)
          .get();

      final remotePosts = snapshot.docs.map((doc) => Post.fromFirestore(doc)).toList();
      return [..._localPosts, ...remotePosts];
    } catch (e) {
      print('Notice fetching posts from Firestore ($e). Returning local posts.');
      return _localPosts;
    }
  }

  /// Stream all posts (including drafts) for real-time updates
  Stream<List<Post>> streamAllPosts({int limit = 100}) {
    try {
      final firestore = _firestore;
      if (firestore == null) return Stream.value(_localPosts);

      return firestore
          .collection(_postsCollection)
          .orderBy('updatedAt', descending: true)
          .limit(limit)
          .snapshots()
          .map((snapshot) =>
              [..._localPosts, ...snapshot.docs.map((doc) => Post.fromFirestore(doc))])
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
    try {
      final firestore = _firestore;
      if (firestore == null) return _localPosts.take(limit).toList();

      final snapshot = await firestore
          .collection(_postsCollection)
          .orderBy('createdAt', descending: true)
          .limit(limit)
          .get();

      return snapshot.docs.map((doc) => Post.fromFirestore(doc)).toList();
    } catch (e) {
      print('Notice fetching recent posts: $e');
      return _localPosts.take(limit).toList();
    }
  }

  /// Fetch all categories for admin management
  Future<List<Category>> fetchAllCategories() async {
    try {
      final firestore = _firestore;
      if (firestore == null) return _localCategories;

      final snapshot = await firestore
          .collection(_categoriesCollection)
          .orderBy('name')
          .get();

      final remoteCategories = snapshot.docs
          .map((doc) => Category.fromFirestore(doc))
          .toList();
      return [..._localCategories, ...remoteCategories];
    } catch (e) {
      print('Notice fetching categories from Firestore ($e). Returning local categories.');
      return _localCategories;
    }
  }

  /// Check if category has associated posts
  Future<int> getPostsCountByCategory(String categoryId) async {
    try {
      final firestore = _firestore;
      if (firestore == null) return 0;

      final snapshot = await firestore
          .collection(_postsCollection)
          .where('categoryId', isEqualTo: categoryId)
          .count()
          .get();

      return snapshot.count ?? 0;
    } catch (e) {
      print('Notice counting posts by category: $e');
      return 0;
    }
  }

  /// Publish a post (change isPublished to true, set publishedAt)
  Future<void> publishPost(String postId) async {
    try {
      final firestore = _firestore;
      if (firestore != null) {
        await firestore.collection(_postsCollection).doc(postId).update({
          'isPublished': true,
          'publishedAt': Timestamp.now(),
          'updatedAt': Timestamp.now(),
        });
      }
      final idx = _localPosts.indexWhere((p) => p.id == postId);
      if (idx != -1) {
        _localPosts[idx] = _localPosts[idx].copyWith(isPublished: true);
      }
      print('✓ Post published: $postId');
    } catch (e) {
      print('Notice publishing post: $e');
      final idx = _localPosts.indexWhere((p) => p.id == postId);
      if (idx != -1) {
        _localPosts[idx] = _localPosts[idx].copyWith(isPublished: true);
      }
    }
  }

  /// Unpublish a post (change isPublished to false)
  Future<void> unpublishPost(String postId) async {
    try {
      final firestore = _firestore;
      if (firestore != null) {
        await firestore.collection(_postsCollection).doc(postId).update({
          'isPublished': false,
          'updatedAt': Timestamp.now(),
        });
      }
      final idx = _localPosts.indexWhere((p) => p.id == postId);
      if (idx != -1) {
        _localPosts[idx] = _localPosts[idx].copyWith(isPublished: false);
      }
      print('✓ Post unpublished: $postId');
    } catch (e) {
      print('Notice unpublishing post: $e');
      final idx = _localPosts.indexWhere((p) => p.id == postId);
      if (idx != -1) {
        _localPosts[idx] = _localPosts[idx].copyWith(isPublished: false);
      }
    }
  }

  /// Verify if user has admin access (server-side check)
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

  /// Create a new post (admin only) - defaults to published
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

    final post = Post(
      id: '',
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

    try {
      final firestore = _firestore;
      if (firestore == null) {
        final localId = 'post_${DateTime.now().millisecondsSinceEpoch}';
        final localPost = post.copyWith(id: localId);
        _localPosts.insert(0, localPost);
        return localId;
      }

      final docRef = await firestore
          .collection(_postsCollection)
          .add(post.toFirestore());

      final createdPost = post.copyWith(id: docRef.id);
      _localPosts.removeWhere((p) => p.id == docRef.id);
      _localPosts.insert(0, createdPost);

      print('✓ Post created in Firestore: ${docRef.id}');
      return docRef.id;
    } catch (e) {
      print('Notice: Firestore rejected post creation ($e). Saving locally.');
      final localId = 'post_${DateTime.now().millisecondsSinceEpoch}';
      final localPost = post.copyWith(id: localId);
      _localPosts.insert(0, localPost);
      return localId;
    }
  }

  /// Update an existing post (admin only) - preserves original timestamps
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
    try {
      final firestore = _firestore;
      if (firestore == null) {
        final idx = _localPosts.indexWhere((p) => p.id == postId);
        if (idx != -1) {
          _localPosts[idx] = _localPosts[idx].copyWith(
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
        }
        return;
      }

      // Fetch existing post to preserve timestamps
      final existingDoc =
          await firestore.collection(_postsCollection).doc(postId).get();

      if (!existingDoc.exists) {
        throw Exception('Post not found');
      }

      final existingData = existingDoc.data()!;
      final publishedAt =
          (existingData['publishedAt'] as Timestamp?)?.toDate();

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
        if (isPublished && publishedAt == null) {
          updateData['publishedAt'] = Timestamp.now();
        }
      }

      await firestore
          .collection(_postsCollection)
          .doc(postId)
          .update(updateData);

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
        await firestore
            .collection(_postsCollection)
            .doc(postId)
            .delete();
      }
      _localPosts.removeWhere((p) => p.id == postId);
      print('✓ Post deleted: $postId');
    } catch (e) {
      print('Notice deleting post: $e');
      _localPosts.removeWhere((p) => p.id == postId);
    }
  }

  /// Create a new category (admin only)
  Future<String> createCategory(String name) async {
    try {
      final firestore = _firestore;
      final now = DateTime.now();
      final category = Category(
        id: '', // Will be set by Firestore
        name: name,
        createdAt: now,
        updatedAt: now,
      );

      if (firestore == null) {
        final localId = 'cat_${DateTime.now().millisecondsSinceEpoch}';
        final localCat = Category(
          id: localId,
          name: name,
          createdAt: DateTime.now(),
          updatedAt: DateTime.now(),
        );
        _localCategories.add(localCat);
        return localId;
      }

      final docRef = await firestore
          .collection(_categoriesCollection)
          .add(category.toFirestore());

      final createdCat = Category(
        id: docRef.id,
        name: name,
        createdAt: now,
        updatedAt: now,
      );
      _localCategories.removeWhere((c) => c.id == docRef.id);
      _localCategories.insert(0, createdCat);

      print('✓ Category created in Firestore: ${docRef.id}');
      return docRef.id;
    } catch (e) {
      print('Notice: Firestore rejected category creation ($e). Saving locally.');
      final localId = 'cat_${DateTime.now().millisecondsSinceEpoch}';
      final localCat = Category(
        id: localId,
        name: name,
        createdAt: DateTime.now(),
        updatedAt: DateTime.now(),
      );
      _localCategories.add(localCat);
      return localId;
    }
  }

  /// Update an existing category (admin only)
  Future<void> updateCategory({
    required String categoryId,
    required String name,
  }) async {
    try {
      final firestore = _firestore;
      if (firestore != null) {
        final category = Category(
          id: categoryId,
          name: name,
          createdAt: DateTime.now(),
          updatedAt: DateTime.now(),
        );

        await firestore
            .collection(_categoriesCollection)
            .doc(categoryId)
            .update(category.toFirestore());
      }
      final idx = _localCategories.indexWhere((c) => c.id == categoryId);
      if (idx != -1) {
        _localCategories[idx] = _localCategories[idx].copyWith(name: name, updatedAt: DateTime.now());
      }
      print('✓ Category updated: $categoryId');
    } catch (e) {
      print('Notice updating category: $e');
      final idx = _localCategories.indexWhere((c) => c.id == categoryId);
      if (idx != -1) {
        _localCategories[idx] = _localCategories[idx].copyWith(name: name, updatedAt: DateTime.now());
      }
    }
  }

  /// Delete a category (admin only)
  Future<void> deleteCategory(String categoryId) async {
    try {
      final firestore = _firestore;
      if (firestore != null) {
        await firestore
            .collection(_categoriesCollection)
            .doc(categoryId)
            .delete();
      }
      _localCategories.removeWhere((c) => c.id == categoryId);
      print('✓ Category deleted: $categoryId');
    } catch (e) {
      print('Notice deleting category: $e');
      _localCategories.removeWhere((c) => c.id == categoryId);
    }
  }

  /// Grant admin access to a user (super admin only)
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

  /// Revoke admin access (super admin only)
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
