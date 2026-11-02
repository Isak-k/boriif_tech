import 'dart:io';
import 'package:flutter/foundation.dart' hide Category;
import '../services/admin_service.dart';
import '../services/storage_service.dart';
import '../models/post_model.dart';
import '../models/category_model.dart';
import '../core/constants/admin_constants.dart';

/// Provider for admin-only operations
class AdminProvider extends ChangeNotifier {
  final AdminService _adminService = AdminService();
  final StorageService _storageService = StorageService();

  bool _isLoading = false;
  String? _errorMessage;
  bool _hasAdminAccess = false;
  double _uploadProgress = 0;
  Map<String, dynamic> _dashboardStats = {
    'totalPosts': 0,
    'publishedPosts': 0,
    'totalViews': 0,
    'totalFavorites': 0,
    'totalCategories': 0,
  };
  List<Post> _allPosts = [];
  List<Category> _categories = [];
  List<Post> _recentPosts = [];

  // Getters
  bool get isLoading => _isLoading;
  String? get errorMessage => _errorMessage;
  bool get hasAdminAccess => _hasAdminAccess;
  double get uploadProgress => _uploadProgress;
  Map<String, dynamic> get dashboardStats => _dashboardStats;
  List<Post> get allPosts => _allPosts;
  List<Category> get categories => _categories;
  List<Post> get recentPosts => _recentPosts;

  /// Set admin access explicitly
  void setAdminAccess(bool value) {
    _hasAdminAccess = value;
    notifyListeners();
  }

  /// Verify admin access
  Future<bool> verifyAdminAccess(String userId, [String? email]) async {
    if (email != null && AdminConstants.isAdminEmail(email)) {
      _hasAdminAccess = true;
      notifyListeners();
      return true;
    }
    try {
      _hasAdminAccess = await _adminService.verifyAdminAccess(userId);
      notifyListeners();
      return _hasAdminAccess;
    } catch (e) {
      if (email != null && AdminConstants.isAdminEmail(email)) {
        _hasAdminAccess = true;
        notifyListeners();
        return true;
      }
      _errorMessage = e.toString();
      _hasAdminAccess = false;
      notifyListeners();
      return false;
    }
  }

  /// Load dashboard statistics
  Future<void> loadDashboardStats() async {
    _isLoading = true;
    _errorMessage = null;
    notifyListeners();

    try {
      _dashboardStats = await _adminService.getDashboardStats();
      _isLoading = false;
      notifyListeners();
    } catch (e) {
      _errorMessage = e.toString();
      _isLoading = false;
      notifyListeners();
    }
  }

  /// Fetch all posts (including drafts)
  Future<void> fetchAllPosts() async {
    _isLoading = true;
    _errorMessage = null;
    notifyListeners();

    try {
      _allPosts = await _adminService.fetchAllPosts();
      _isLoading = false;
      notifyListeners();
    } catch (e) {
      _errorMessage = e.toString();
      _isLoading = false;
      notifyListeners();
    }
  }

  /// Load recent posts for dashboard
  Future<void> loadRecentPosts() async {
    try {
      _recentPosts = await _adminService.fetchRecentPosts();
      notifyListeners();
    } catch (e) {
      print('Error loading recent posts: $e');
    }
  }

  /// Fetch all categories
  Future<void> fetchCategories() async {
    _isLoading = true;
    _errorMessage = null;
    notifyListeners();

    try {
      _categories = await _adminService.fetchAllCategories();
      _isLoading = false;
      notifyListeners();
    } catch (e) {
      _errorMessage = e.toString();
      _isLoading = false;
      notifyListeners();
    }
  }

  /// Create a new post
  Future<String?> createPost({
    required String title,
    required String shortDescription,
    required String description,
    required String postType,
    required String categoryId,
    String? code,
    String? imageUrl,
    String? playStoreUrl,
    String? externalUrl,
    bool isPublished = false,
  }) async {
    if (!_hasAdminAccess) {
      _errorMessage = 'You do not have admin access';
      notifyListeners();
      return null;
    }

    _isLoading = true;
    _errorMessage = null;
    notifyListeners();

    try {
      final postId = await _adminService.createPost(
        title: title,
        shortDescription: shortDescription,
        description: description,
        postType: postType,
        categoryId: categoryId,
        code: code,
        imageUrl: imageUrl,
        playStoreUrl: playStoreUrl,
        externalUrl: externalUrl,
        isPublished: isPublished,
      );

      _isLoading = false;
      await fetchAllPosts();
      notifyListeners();
      return postId;
    } catch (e) {
      _errorMessage = e.toString();
      _isLoading = false;
      notifyListeners();
      return null;
    }
  }

  /// Update a post
  Future<bool> updatePost({
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
    if (!_hasAdminAccess) {
      _errorMessage = 'You do not have admin access';
      notifyListeners();
      return false;
    }

    _isLoading = true;
    _errorMessage = null;
    notifyListeners();

    try {
      await _adminService.updatePost(
        postId: postId,
        title: title,
        shortDescription: shortDescription,
        description: description,
        postType: postType,
        categoryId: categoryId,
        code: code,
        imageUrl: imageUrl,
        playStoreUrl: playStoreUrl,
        externalUrl: externalUrl,
        isPublished: isPublished,
      );

      _isLoading = false;
      await fetchAllPosts();
      notifyListeners();
      return true;
    } catch (e) {
      _errorMessage = e.toString();
      _isLoading = false;
      notifyListeners();
      return false;
    }
  }

  /// Delete a post
  Future<bool> deletePost(String postId) async {
    if (!_hasAdminAccess) {
      _errorMessage = 'You do not have admin access';
      notifyListeners();
      return false;
    }

    _isLoading = true;
    _errorMessage = null;
    notifyListeners();

    try {
      await _adminService.deletePost(postId);
      _isLoading = false;
      await fetchAllPosts();
      notifyListeners();
      return true;
    } catch (e) {
      _errorMessage = e.toString();
      _isLoading = false;
      notifyListeners();
      return false;
    }
  }

  /// Publish a post
  Future<bool> publishPost(String postId) async {
    if (!_hasAdminAccess) {
      _errorMessage = 'You do not have admin access';
      notifyListeners();
      return false;
    }

    _isLoading = true;
    _errorMessage = null;
    notifyListeners();

    try {
      await _adminService.publishPost(postId);
      _isLoading = false;
      await fetchAllPosts();
      notifyListeners();
      return true;
    } catch (e) {
      _errorMessage = e.toString();
      _isLoading = false;
      notifyListeners();
      return false;
    }
  }

  /// Unpublish a post
  Future<bool> unpublishPost(String postId) async {
    if (!_hasAdminAccess) {
      _errorMessage = 'You do not have admin access';
      notifyListeners();
      return false;
    }

    _isLoading = true;
    _errorMessage = null;
    notifyListeners();

    try {
      await _adminService.unpublishPost(postId);
      _isLoading = false;
      await fetchAllPosts();
      notifyListeners();
      return true;
    } catch (e) {
      _errorMessage = e.toString();
      _isLoading = false;
      notifyListeners();
      return false;
    }
  }

  /// Create a new category
  Future<bool> createCategory(String name) async {
    if (!_hasAdminAccess) {
      _errorMessage = 'You do not have admin access';
      notifyListeners();
      return false;
    }

    _isLoading = true;
    _errorMessage = null;
    notifyListeners();

    try {
      await _adminService.createCategory(name);
      _isLoading = false;
      await fetchCategories();
      notifyListeners();
      return true;
    } catch (e) {
      _errorMessage = e.toString();
      _isLoading = false;
      notifyListeners();
      return false;
    }
  }

  /// Update a category
  Future<bool> updateCategory({
    required String categoryId,
    required String name,
  }) async {
    if (!_hasAdminAccess) {
      _errorMessage = 'You do not have admin access';
      notifyListeners();
      return false;
    }

    _isLoading = true;
    _errorMessage = null;
    notifyListeners();

    try {
      await _adminService.updateCategory(
        categoryId: categoryId,
        name: name,
      );

      _isLoading = false;
      await fetchCategories();
      notifyListeners();
      return true;
    } catch (e) {
      _errorMessage = e.toString();
      _isLoading = false;
      notifyListeners();
      return false;
    }
  }

  /// Delete a category (with safeguard checking)
  Future<bool> deleteCategory(String categoryId) async {
    if (!_hasAdminAccess) {
      _errorMessage = 'You do not have admin access';
      notifyListeners();
      return false;
    }

    _isLoading = true;
    _errorMessage = null;
    notifyListeners();

    try {
      // Check if category has associated posts
      final postCount = await _adminService.getPostsCountByCategory(categoryId);
      if (postCount > 0) {
        _errorMessage = 'Cannot delete category with $postCount associated posts. Please reassign posts first.';
        _isLoading = false;
        notifyListeners();
        return false;
      }

      await _adminService.deleteCategory(categoryId);
      _isLoading = false;
      await fetchCategories();
      notifyListeners();
      return true;
    } catch (e) {
      _errorMessage = e.toString();
      _isLoading = false;
      notifyListeners();
      return false;
    }
  }

  /// Upload image file
  Future<String?> uploadImage(File imageFile) async {
    _isLoading = true;
    _uploadProgress = 0;
    _errorMessage = null;
    notifyListeners();

    try {
      final fileName = 'post-${DateTime.now().millisecondsSinceEpoch}';
      final url = await _storageService.uploadImage(
        file: imageFile,
        folder: 'posts',
        fileName: fileName,
      );

      _isLoading = false;
      _uploadProgress = 1;
      notifyListeners();
      return url;
    } catch (e) {
      _errorMessage = 'Failed to upload image: ${e.toString()}';
      _isLoading = false;
      _uploadProgress = 0;
      notifyListeners();
      return null;
    }
  }

  /// Reset upload progress
  void resetUploadProgress() {
    _uploadProgress = 0;
    notifyListeners();
  }

  /// Clear error message
  void clearError() {
    _errorMessage = null;
    notifyListeners();
  }
}
