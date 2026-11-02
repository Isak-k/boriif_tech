import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_core/firebase_core.dart';
import '../models/category_model.dart';
import 'admin_service.dart';
import 'offline_cache_service.dart';

/// Service for handling Category data from Firestore with offline persistence
class CategoryService {
  FirebaseFirestore? get _firestore {
    try {
      if (Firebase.apps.isNotEmpty) {
        return FirebaseFirestore.instance;
      }
    } catch (_) {}
    return null;
  }

  /// Collection name
  static const String _categoriesCollection = 'categories';

  /// Fetch all categories (merging remote, local, and offline cache)
  Future<List<Category>> fetchCategories() async {
    try {
      final firestore = _firestore;
      if (firestore == null) {
        final cached = await OfflineCacheService.getCachedCategories();
        if (cached.isNotEmpty) return cached;
        return AdminService.localCategories;
      }

      final snapshot = await firestore
          .collection(_categoriesCollection)
          .orderBy('name')
          .get();

      final remoteCategories = snapshot.docs
          .map((doc) => Category.fromFirestore(doc))
          .toList();

      final combined = <Category>[...remoteCategories];
      for (final local in AdminService.localCategories) {
        if (!combined.any((c) => c.id == local.id || c.name.toLowerCase() == local.name.toLowerCase())) {
          combined.add(local);
        }
      }

      // Automatically save to local offline cache
      await OfflineCacheService.saveCategories(combined);

      return combined;
    } catch (e) {
      print('Notice fetching categories from Firestore ($e). Loading cached categories.');
      final cached = await OfflineCacheService.getCachedCategories();
      if (cached.isNotEmpty) return cached;
      return AdminService.localCategories;
    }
  }

  /// Listen to categories in real time
  Stream<List<Category>> streamCategories() {
    try {
      final firestore = _firestore;
      if (firestore == null) {
        return Stream.fromFuture(OfflineCacheService.getCachedCategories()).map((cached) {
          if (cached.isNotEmpty) return cached;
          return AdminService.localCategories;
        });
      }

      return firestore
          .collection(_categoriesCollection)
          .orderBy('name')
          .snapshots()
          .asyncMap((snapshot) async {
            final remoteCategories = snapshot.docs
                .map((doc) => Category.fromFirestore(doc))
                .toList();

            final combined = <Category>[...remoteCategories];
            for (final local in AdminService.localCategories) {
              if (!combined.any((c) => c.id == local.id || c.name.toLowerCase() == local.name.toLowerCase())) {
                combined.add(local);
              }
            }

            // Save to offline cache
            await OfflineCacheService.saveCategories(combined);
            return combined;
          })
          .handleError((error) async {
            print('Notice streaming categories error: $error');
            final cached = await OfflineCacheService.getCachedCategories();
            if (cached.isNotEmpty) return cached;
            return AdminService.localCategories;
          });
    } catch (e) {
      print('Notice streaming categories: $e');
      return Stream.value(AdminService.localCategories);
    }
  }

  /// Fetch a single category by ID
  Future<Category?> fetchCategoryById(String categoryId) async {
    try {
      // Check local cache first
      final local = AdminService.localCategories.where((c) => c.id == categoryId).firstOrNull;
      if (local != null) return local;

      final firestore = _firestore;
      if (firestore != null) {
        final doc = await firestore
            .collection(_categoriesCollection)
            .doc(categoryId)
            .get();

        if (doc.exists) {
          return Category.fromFirestore(doc);
        }
      }

      final cached = await OfflineCacheService.getCachedCategories();
      return cached.where((c) => c.id == categoryId).firstOrNull;
    } catch (e) {
      print('Notice fetching category: $e');
      final cached = await OfflineCacheService.getCachedCategories();
      return cached.where((c) => c.id == categoryId).firstOrNull;
    }
  }

  /// Create a new category (admin only)
  Future<String> createCategory(Category category) async {
    try {
      final firestore = _firestore;
      if (firestore == null) {
        AdminService.localCategories.add(category);
        return category.id;
      }

      final docRef = await firestore
          .collection(_categoriesCollection)
          .add(category.toFirestore());
      print('✓ Category created: ${docRef.id}');
      return docRef.id;
    } catch (e) {
      print('✗ Error creating category: $e');
      AdminService.localCategories.add(category);
      return category.id;
    }
  }

  /// Update a category (admin only)
  Future<void> updateCategory(String categoryId, Category category) async {
    try {
      final firestore = _firestore;
      if (firestore == null) throw Exception('Database not available');

      await firestore
          .collection(_categoriesCollection)
          .doc(categoryId)
          .update(category.toFirestore());
      print('✓ Category updated: $categoryId');
    } catch (e) {
      print('✗ Error updating category: $e');
      rethrow;
    }
  }

  /// Delete a category (admin only)
  Future<void> deleteCategory(String categoryId) async {
    try {
      final firestore = _firestore;
      if (firestore == null) throw Exception('Database not available');

      await firestore
          .collection(_categoriesCollection)
          .doc(categoryId)
          .delete();
      print('✓ Category deleted: $categoryId');
    } catch (e) {
      print('✗ Error deleting category: $e');
      rethrow;
    }
  }

  /// Get post count for a category (supports 'all' for all categories)
  Future<int> getPostCountForCategory(String categoryId) async {
    try {
      final firestore = _firestore;
      if (categoryId == 'all' || categoryId.isEmpty) {
        int localCount = AdminService.localPosts.where((p) => p.isPublished).length;
        if (firestore == null) return localCount;
        final snapshot = await firestore
            .collection('posts')
            .where('isPublished', isEqualTo: true)
            .count()
            .get();
        return (snapshot.count ?? 0) + localCount;
      }

      int localCount = AdminService.localPosts
          .where((p) => p.categoryId == categoryId && p.isPublished)
          .length;

      if (firestore == null) return localCount;

      final snapshot = await firestore
          .collection('posts')
          .where('categoryId', isEqualTo: categoryId)
          .where('isPublished', isEqualTo: true)
          .count()
          .get();

      return (snapshot.count ?? 0) + localCount;
    } catch (e) {
      print('Notice fetching post count: $e');
      if (categoryId == 'all' || categoryId.isEmpty) {
        return AdminService.localPosts.where((p) => p.isPublished).length;
      }
      return AdminService.localPosts
          .where((p) => p.categoryId == categoryId && p.isPublished)
          .length;
    }
  }
}
