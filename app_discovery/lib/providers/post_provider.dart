import 'package:flutter/foundation.dart';
import '../models/post_model.dart';
import '../services/post_service.dart';
import '../services/favorites_service.dart';
import '../services/view_counter_service.dart';

/// Provider for managing posts state with real-time updates
class PostProvider extends ChangeNotifier {
  final PostService _postService = PostService();
  final FavoritesService _favoritesService = FavoritesService();
  final ViewCounterService _viewCounterService = ViewCounterService();

  List<Post> _posts = [];
  Post? _selectedPost;
  bool _isLoading = false;
  String? _errorMessage;
  String? _selectedCategoryId;
  List<Post> _favoritePosts = [];
  List<String> _favoritePostIds = [];
  bool _favoritesInitialized = false;

  // Getters
  List<Post> get posts => _posts;
  Post? get selectedPost => _selectedPost;
  bool get isLoading => _isLoading;
  String? get errorMessage => _errorMessage;
  String? get selectedCategoryId => _selectedCategoryId;
  List<Post> get favoritePosts => _favoritePosts;

  /// Initialize the provider
  Future<void> init() async {
    await _initializeFavorites();
  }

  /// Initialize favorites from local storage
  Future<void> _initializeFavorites() async {
    try {
      await _favoritesService.init();
      _favoritePostIds = await _favoritesService.getFavorites();
      _favoritesInitialized = true;
      print('✓ Favorites initialized: ${_favoritePostIds.length} items');
      notifyListeners();
    } catch (e) {
      print('✗ Error initializing favorites: $e');
    }
  }

  /// Fetch published posts (one-time)
  Future<void> fetchPublishedPosts() async {
    _isLoading = true;
    _errorMessage = null;
    notifyListeners();

    try {
      _posts = await _postService.fetchPublishedPosts();
      await _updateFavoritesList();
      await _cleanupFavorites();
      _isLoading = false;
      notifyListeners();
    } catch (e) {
      _errorMessage = e.toString();
      _isLoading = false;
      notifyListeners();
    }
  }

  /// Listen to published posts in real time
  void listenToPublishedPosts() {
    try {
      _postService.streamPublishedPosts().listen(
        (posts) async {
          _posts = posts;
          await _updateFavoritesList();
          await _cleanupFavorites();
          notifyListeners();
        },
        onError: (error) {
          _errorMessage = error.toString();
          notifyListeners();
        },
      );
    } catch (e) {
      _errorMessage = e.toString();
      notifyListeners();
    }
  }

  /// Update favorites list based on current posts and local favorites
  Future<void> _updateFavoritesList() async {
    if (!_favoritesInitialized) return;

    try {
      _favoritePosts = _posts
          .where((post) => _favoritePostIds.contains(post.id))
          .map((post) => post.copyWith(isFavorite: true))
          .toList();
    } catch (e) {
      print('✗ Error updating favorites list: $e');
    }
  }

  /// Clean up favorites for deleted/unpublished posts
  Future<void> _cleanupFavorites() async {
    if (!_favoritesInitialized) return;

    try {
      final existingPostIds = _posts.map((post) => post.id).toList();
      await _favoritesService.cleanupDeletedPosts(existingPostIds);
      
      // Refresh local favorites list
      _favoritePostIds = await _favoritesService.getFavorites();
      await _updateFavoritesList();
    } catch (e) {
      print('✗ Error cleaning up favorites: $e');
    }
  }

  /// Fetch posts by category
  Future<void> fetchPostsByCategory(String categoryId) async {
    _selectedCategoryId = categoryId;
    _isLoading = true;
    _errorMessage = null;
    notifyListeners();

    try {
      if (categoryId == 'all' || categoryId.isEmpty) {
        _posts = await _postService.fetchPublishedPosts();
      } else {
        _posts = await _postService.fetchPostsByCategory(categoryId);
      }
      await _updateFavoritesList();
      _isLoading = false;
      notifyListeners();
    } catch (e) {
      _errorMessage = e.toString();
      _isLoading = false;
      notifyListeners();
    }
  }

  /// Set selected post synchronously for immediate (0ms) rendering
  void setSelectedPost(Post post) {
    _selectedPost = post;
    _errorMessage = null;
    _isLoading = false;
    notifyListeners();
  }

  /// Record view silently in the background without triggering loading spinners
  Future<void> recordViewSilently(String postId) async {
    try {
      final wasCounted = await _viewCounterService.recordView(postId);
      if (wasCounted) {
        if (_selectedPost != null && _selectedPost!.id == postId) {
          final updatedViews = _selectedPost!.viewsCount + 1;
          _selectedPost = _selectedPost!.copyWith(viewsCount: updatedViews);
        }
        final idx = _posts.indexWhere((p) => p.id == postId);
        if (idx != -1) {
          final updatedViews = _posts[idx].viewsCount + 1;
          _posts[idx] = _posts[idx].copyWith(viewsCount: updatedViews);
        }
        notifyListeners();
      }
    } catch (e) {
      print('✗ Error recording view silently: $e');
    }
  }

  /// Fetch a single post by ID with performance optimizations:
  /// Uses existing in-memory/cached post data immediately when available.
  Future<void> fetchPostById(String postId, {Post? initialPost}) async {
    if (initialPost != null) {
      _selectedPost = initialPost;
      _isLoading = false;
      _errorMessage = null;
      notifyListeners();
      await recordViewSilently(postId);
      return;
    }

    // Check if post already exists in memory
    final existingPost = _posts.where((p) => p.id == postId).firstOrNull ??
        _favoritePosts.where((p) => p.id == postId).firstOrNull;

    if (existingPost != null) {
      _selectedPost = existingPost;
      _isLoading = false;
      _errorMessage = null;
      notifyListeners();
      await recordViewSilently(postId);
      return;
    }

    // Only if post is not in memory, show loading and fetch from service
    _isLoading = true;
    _errorMessage = null;
    notifyListeners();

    try {
      _selectedPost = await _postService.fetchPostById(postId);
      _isLoading = false;
      notifyListeners();

      if (_selectedPost != null) {
        await recordViewSilently(postId);
      }
    } catch (e) {
      _errorMessage = e.toString();
      _isLoading = false;
      notifyListeners();
    }
  }

  /// Fetch posts by type (app, article, job)
  Future<void> fetchPostsByType(String postType) async {
    _isLoading = true;
    _errorMessage = null;
    notifyListeners();

    try {
      _posts = await _postService.fetchPostsByType(postType);
      await _updateFavoritesList();
      _isLoading = false;
      notifyListeners();
    } catch (e) {
      _errorMessage = e.toString();
      _isLoading = false;
      notifyListeners();
    }
  }

  /// Search posts
  Future<void> searchPosts(String query) async {
    if (query.isEmpty) {
      await fetchPublishedPosts();
      return;
    }

    _isLoading = true;
    _errorMessage = null;
    notifyListeners();

    try {
      _posts = await _postService.searchPosts(query);
      await _updateFavoritesList();
      _isLoading = false;
      notifyListeners();
    } catch (e) {
      _errorMessage = e.toString();
      _isLoading = false;
      notifyListeners();
    }
  }

  /// Add post to favorites / likes (with persistence & cloud sync)
  Future<void> addToFavorites(Post post) async {
    try {
      if (!_favoritesInitialized) {
        await _initializeFavorites();
      }

      final success = await _favoritesService.addFavorite(post.id);
      if (success) {
        if (!_favoritePostIds.contains(post.id)) {
          _favoritePostIds.add(post.id);
        }

        // Increment cloud and local likes count
        await _postService.incrementLikes(post.id, 1);

        // Update post in _posts list
        final idx = _posts.indexWhere((p) => p.id == post.id);
        final updatedLikes = (idx != -1 ? _posts[idx].likesCount : post.likesCount) + 1;

        if (idx != -1) {
          _posts[idx] = _posts[idx].copyWith(
            likesCount: updatedLikes,
            isFavorite: true,
          );
        }

        if (_selectedPost != null && _selectedPost!.id == post.id) {
          _selectedPost = _selectedPost!.copyWith(
            likesCount: updatedLikes,
            isFavorite: true,
          );
        }

        _favoritePosts.removeWhere((p) => p.id == post.id);
        _favoritePosts.add(post.copyWith(
          likesCount: updatedLikes,
          isFavorite: true,
        ));

        notifyListeners();
      }
    } catch (e) {
      print('✗ Error adding to favorites: $e');
    }
  }

  /// Remove post from favorites / likes (with persistence & cloud sync)
  Future<void> removeFromFavorites(String postId) async {
    try {
      if (!_favoritesInitialized) {
        await _initializeFavorites();
      }

      final success = await _favoritesService.removeFavorite(postId);
      if (success) {
        _favoritePostIds.remove(postId);

        // Decrement cloud and local likes count
        await _postService.incrementLikes(postId, -1);

        final idx = _posts.indexWhere((p) => p.id == postId);
        if (idx != -1) {
          final curLikes = _posts[idx].likesCount;
          _posts[idx] = _posts[idx].copyWith(
            likesCount: curLikes > 0 ? curLikes - 1 : 0,
            isFavorite: false,
          );
        }

        if (_selectedPost != null && _selectedPost!.id == postId) {
          final curLikes = _selectedPost!.likesCount;
          _selectedPost = _selectedPost!.copyWith(
            likesCount: curLikes > 0 ? curLikes - 1 : 0,
            isFavorite: false,
          );
        }

        _favoritePosts.removeWhere((p) => p.id == postId);
        notifyListeners();
      }
    } catch (e) {
      print('✗ Error removing from favorites: $e');
    }
  }

  /// Check if post is favorite
  bool isFavorite(String postId) {
    return _favoritePostIds.contains(postId);
  }

  /// Get favorites count
  int get favoritesCount => _favoritePostIds.length;

  /// Refresh all data
  Future<void> refresh() async {
    await fetchPublishedPosts();
    await _initializeFavorites();
  }

  /// Clear selected post
  void clearSelectedPost() {
    _selectedPost = null;
    notifyListeners();
  }

  /// Clear error message
  void clearError() {
    _errorMessage = null;
    notifyListeners();
  }

  /// Get view count for a post
  Future<int> getViewCount(String postId) async {
    return await _viewCounterService.getViewCount(postId);
  }

  /// Clear favorites (for testing/reset)
  Future<void> clearFavorites() async {
    try {
      await _favoritesService.clearFavorites();
      _favoritePostIds.clear();
      _favoritePosts.clear();
      notifyListeners();
    } catch (e) {
      print('✗ Error clearing favorites: $e');
    }
  }
}
