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
    await AdminService.hydrateFromDisk();

    try {
      final firestore = _firestore;
      if (firestore == null) {
        final cached = await OfflineCacheService.getCachedCategories();
        if (cached.isNotEmpty) return cached;
        return AdminService.localCategories;
      }

      QuerySnapshot<Map<String, dynamic>> snapshot;
      try {
        snapshot = await firestore
            .collection(_categoriesCollection)
            .orderBy('name')
            .get();
      } catch (_) {
        snapshot = await firestore
            .collection(_categoriesCollection)
            .get();
      }

      final remoteCategories = snapshot.docs
          .map((doc) => Category.fromFirestore(doc))
          .toList();

      final combined = <Category>[...remoteCategories];
      for (final local in AdminService.localCategories) {
        if (!combined.any((c) => c.id == local.id || c.name.toLowerCase() == local.name.toLowerCase())) {
          combined.add(local);
        }
      }

      final cached = await OfflineCacheService.getCachedCategories();
      for (final c in cached) {
        if (!combined.any((cat) => cat.id == c.id || cat.name.toLowerCase() == c.name.toLowerCase())) {
          combined.add(c);
        }
      }

      combined.sort((a, b) => a.name.toLowerCase().compareTo(b.name.toLowerCase()));

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
    AdminService.hydrateFromDisk();

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

            final cached = await OfflineCacheService.getCachedCategories();
            for (final c in cached) {
              if (!combined.any((cat) => cat.id == c.id || cat.name.toLowerCase() == c.name.toLowerCase())) {
                combined.add(c);
              }
            }

            combined.sort((a, b) => a.name.toLowerCase().compareTo(b.name.toLowerCase()));
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
    await AdminService.hydrateFromDisk();

    try {
      final local = AdminService.localCategories.where((c) => c.id == categoryId).firstOrNull;
      if (local != null) return local;

      final cached = await OfflineCacheService.getCachedCategories();
      final cCat = cached.where((c) => c.id == categoryId).firstOrNull;
      if (cCat != null) return cCat;

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

      return null;
    } catch (e) {
      print('Notice fetching category: $e');
      final cached = await OfflineCacheService.getCachedCategories();
      return cached.where((c) => c.id == categoryId).firstOrNull;
    }
  }

  /// Create a new category (admin only)
  Future<String> createCategory(Category category) async {
    return AdminService().createCategory(category.name);
  }

  /// Update a category (admin only)
  Future<void> updateCategory(String categoryId, Category category) async {
    return AdminService().updateCategory(categoryId: categoryId, name: category.name);
  }

  /// Delete a category (admin only)
  Future<void> deleteCategory(String categoryId) async {
    return AdminService().deleteCategory(categoryId);
  }

  /// Get post count for a category (supports 'all' for all categories)
  Future<int> getPostCountForCategory(String categoryId) async {
    await AdminService.hydrateFromDisk();
    final cached = await OfflineCacheService.getCachedPosts();
    final activePosts = cached.isNotEmpty ? cached : AdminService.localPosts;

    if (categoryId == 'all' || categoryId.isEmpty) {
      return activePosts.where((p) => p.isPublished).length;
    }

    final query = categoryId.toLowerCase();
    return activePosts.where((p) {
      if (!p.isPublished) return false;
      return p.categoryId.toLowerCase() == query;
    }).length;
  }
}
