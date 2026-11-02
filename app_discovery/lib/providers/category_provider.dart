import 'package:flutter/foundation.dart' hide Category;
import '../models/category_model.dart';
import '../services/category_service.dart';

/// Provider for managing categories state
class CategoryProvider extends ChangeNotifier {
  final CategoryService _categoryService = CategoryService();

  /// Default 'All' category that includes posts from all categories
  static final Category allCategory = Category(
    id: 'all',
    name: 'All',
    createdAt: DateTime(2020),
    updatedAt: DateTime(2020),
  );

  List<Category> _categories = [];
  Category? _selectedCategory;
  bool _isLoading = false;
  String? _errorMessage;
  Map<String, int> _postCounts = {};

  // Getters
  List<Category> get categories => _categories;
  Category? get selectedCategory => _selectedCategory;
  bool get isLoading => _isLoading;
  String? get errorMessage => _errorMessage;
  Map<String, int> get postCounts => _postCounts;

  /// Fetch all categories (always includes 'All' at index 0)
  Future<void> fetchCategories() async {
    _isLoading = true;
    _errorMessage = null;
    notifyListeners();

    try {
      final fetched = await _categoryService.fetchCategories();
      final list = List<Category>.from(fetched)..removeWhere((c) => c.id == 'all');
      _categories = [allCategory, ...list];

      // Fetch post counts for each category
      for (var category in _categories) {
        _postCounts[category.id] = 
            await _categoryService.getPostCountForCategory(category.id);
      }

      _isLoading = false;
      notifyListeners();
    } catch (e) {
      _errorMessage = e.toString();
      _isLoading = false;
      notifyListeners();
    }
  }

  /// Listen to categories in real time
  void listenToCategories() {
    try {
      _categoryService.streamCategories().listen((categories) async {
        final list = List<Category>.from(categories)..removeWhere((c) => c.id == 'all');
        _categories = [allCategory, ...list];
        for (var category in _categories) {
          _postCounts[category.id] = 
              await _categoryService.getPostCountForCategory(category.id);
        }
        notifyListeners();
      });
    } catch (e) {
      _errorMessage = e.toString();
      notifyListeners();
    }
  }

  /// Fetch a single category by ID
  Future<void> fetchCategoryById(String categoryId) async {
    if (categoryId == 'all') {
      _selectedCategory = allCategory;
      _postCounts['all'] = await _categoryService.getPostCountForCategory('all');
      notifyListeners();
      return;
    }

    _isLoading = true;
    _errorMessage = null;
    notifyListeners();

    try {
      _selectedCategory = await _categoryService.fetchCategoryById(categoryId);
      if (_selectedCategory != null) {
        _postCounts[categoryId] = 
            await _categoryService.getPostCountForCategory(categoryId);
      }
      _isLoading = false;
      notifyListeners();
    } catch (e) {
      _errorMessage = e.toString();
      _isLoading = false;
      notifyListeners();
    }
  }

  /// Get post count for category
  Future<int> getPostCount(String categoryId) async {
    if (_postCounts.containsKey(categoryId)) {
      return _postCounts[categoryId] ?? 0;
    }

    try {
      final count = await _categoryService.getPostCountForCategory(categoryId);
      _postCounts[categoryId] = count;
      notifyListeners();
      return count;
    } catch (e) {
      print('Error fetching post count: $e');
      return 0;
    }
  }

  /// Create category (admin)
  Future<bool> createCategory(Category category) async {
    _isLoading = true;
    _errorMessage = null;
    notifyListeners();

    try {
      await _categoryService.createCategory(category);
      _isLoading = false;
      notifyListeners();
      await fetchCategories();
      return true;
    } catch (e) {
      _errorMessage = e.toString();
      _isLoading = false;
      notifyListeners();
      return false;
    }
  }

  /// Update category (admin)
  Future<bool> updateCategory(String categoryId, Category category) async {
    _isLoading = true;
    _errorMessage = null;
    notifyListeners();

    try {
      await _categoryService.updateCategory(categoryId, category);
      _isLoading = false;
      notifyListeners();
      await fetchCategories();
      return true;
    } catch (e) {
      _errorMessage = e.toString();
      _isLoading = false;
      notifyListeners();
      return false;
    }
  }

  /// Delete category (admin)
  Future<bool> deleteCategory(String categoryId) async {
    _isLoading = true;
    _errorMessage = null;
    notifyListeners();

    try {
      await _categoryService.deleteCategory(categoryId);
      _isLoading = false;
      notifyListeners();
      await fetchCategories();
      return true;
    } catch (e) {
      _errorMessage = e.toString();
      _isLoading = false;
      notifyListeners();
      return false;
    }
  }

  /// Clear selected category
  void clearSelectedCategory() {
    _selectedCategory = null;
    notifyListeners();
  }

  /// Clear error message
  void clearError() {
    _errorMessage = null;
    notifyListeners();
  }
}
