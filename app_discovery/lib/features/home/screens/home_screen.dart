import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../../widgets/app_bar_widget.dart';
import '../../../widgets/bottom_navigation_widget.dart';
import '../../../widgets/post_card_widget.dart';
import '../../../widgets/loading_indicator_widget.dart';
import '../../../widgets/empty_state_widget.dart';
import '../../../widgets/recent_posts_marquee_widget.dart';
import '../../../core/routing/app_router.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/localization/app_strings.dart';
import '../../../models/post_model.dart';
import '../../../providers/post_provider.dart';
import '../../../providers/category_provider.dart';
import '../../../providers/settings_provider.dart';

class HomeScreen extends StatefulWidget {
  final bool showBottomNav;
  final ValueChanged<int>? onTabSelect;

  const HomeScreen({
    super.key,
    this.showBottomNav = true,
    this.onTabSelect,
  });

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  final TextEditingController _searchController = TextEditingController();
  String _searchQuery = '';
  String _selectedCategoryId = 'all';

  @override
  void initState() {
    super.initState();
    // Initialize and fetch posts & categories when screen loads
    WidgetsBinding.instance.addPostFrameCallback((_) async {
      final postProvider = context.read<PostProvider>();
      final categoryProvider = context.read<CategoryProvider>();

      await postProvider.init(); // Initialize favorites
      postProvider.listenToPublishedPosts(); // Start real-time listening & offline caching
      categoryProvider.fetchCategories(); // Fetch categories including 'All'
    });
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  List<Post> _filterPosts(List<Post> allPosts, CategoryProvider categoryProvider) {
    var result = allPosts;

    // Filter by Category if not 'all'
    if (_selectedCategoryId != 'all' && _selectedCategoryId.isNotEmpty) {
      final selectedCat = categoryProvider.categories.where((c) => c.id == _selectedCategoryId).firstOrNull;
      final queryId = _selectedCategoryId.trim().toLowerCase();
      final queryName = selectedCat?.name.trim().toLowerCase() ?? '';

      result = result.where((p) {
        final pCat = p.categoryId.trim().toLowerCase();
        return pCat == queryId || (queryName.isNotEmpty && pCat == queryName);
      }).toList();
    }

    // Filter by Title or Code
    if (_searchQuery.isNotEmpty) {
      final q = _searchQuery.toLowerCase();
      result = result.where((post) {
        final matchesTitle = post.title.toLowerCase().contains(q);
        final matchesCode = post.code.toLowerCase().contains(q);
        final matchesDesc = post.shortDescription.toLowerCase().contains(q);
        return matchesTitle || matchesCode || matchesDesc;
      }).toList();
    }

    return result;
  }

  void _showLanguageDialog(BuildContext context) {
    final settings = context.read<SettingsProvider>();
    final currentLang = settings.language;

    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        backgroundColor: const Color(0xFF131A29),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        title: Row(
          children: const [
            Icon(Icons.language, color: AppColors.cyan),
            SizedBox(width: 10),
            Text('Language / Afaan', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 18, color: Colors.white)),
          ],
        ),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: SettingsProvider.getAvailableLanguages().map((lang) {
            final isSelected = currentLang == lang['code'];
            return Container(
              margin: const EdgeInsets.symmetric(vertical: 4),
              decoration: BoxDecoration(
                color: isSelected ? AppColors.cyan.withValues(alpha: 0.15) : Colors.transparent,
                borderRadius: BorderRadius.circular(10),
                border: Border.all(
                  color: isSelected ? AppColors.cyan : Colors.white12,
                ),
              ),
              child: ListTile(
                title: Text(
                  lang['name'] ?? '',
                  style: TextStyle(
                    color: isSelected ? AppColors.cyan : Colors.white,
                    fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
                  ),
                ),
                trailing: isSelected ? const Icon(Icons.check_circle, color: AppColors.cyan) : null,
                onTap: () {
                  settings.setLanguage(lang['code']!);
                  Navigator.pop(ctx);
                },
              ),
            );
          }).toList(),
        ),
      ),
    );
  }

  void _showNotificationsDialog(BuildContext context) {
    showModalBottomSheet(
      context: context,
      backgroundColor: const Color(0xFF111726),
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (ctx) => Padding(
        padding: const EdgeInsets.all(20),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Row(
                  children: const [
                    Icon(Icons.notifications_active, color: AppColors.cyan, size: 22),
                    SizedBox(width: 10),
                    Text(
                      'Notifications',
                      style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: Colors.white),
                    ),
                  ],
                ),
                IconButton(
                  icon: const Icon(Icons.close, color: Colors.white70),
                  onPressed: () => Navigator.pop(ctx),
                ),
              ],
            ),
            const Divider(color: Colors.white12),
            const SizedBox(height: 8),
            _buildNotificationItem(
              icon: Icons.offline_pin,
              iconColor: AppColors.cyan,
              title: 'Offline Sync Active',
              message: 'All published posts & categories are automatically saved to your device for offline reading.',
              time: 'Active',
            ),
            const SizedBox(height: 12),
            _buildNotificationItem(
              icon: Icons.cloud_done,
              iconColor: Colors.green,
              title: 'Cloud Database Ready',
              message: 'Connected to Boriif Tech services. New content is synchronized in real time.',
              time: 'Online',
            ),
            const SizedBox(height: 16),
          ],
        ),
      ),
    );
  }

  Widget _buildNotificationItem({
    required IconData icon,
    required Color iconColor,
    required String title,
    required String message,
    required String time,
  }) {
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: const Color(0xFF182236),
        borderRadius: BorderRadius.circular(10),
        border: Border.all(color: Colors.white10),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          CircleAvatar(
            radius: 18,
            backgroundColor: iconColor.withValues(alpha: 0.2),
            child: Icon(icon, color: iconColor, size: 20),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text(
                      title,
                      style: const TextStyle(fontWeight: FontWeight.bold, color: Colors.white, fontSize: 14),
                    ),
                    Text(
                      time,
                      style: const TextStyle(color: Colors.white54, fontSize: 11),
                    ),
                  ],
                ),
                const SizedBox(height: 4),
                Text(
                  message,
                  style: const TextStyle(color: Colors.white70, fontSize: 12),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Consumer<SettingsProvider>(
      builder: (context, settings, _) {
        final lang = settings.language;

        return Scaffold(
          backgroundColor: Colors.transparent,
          appBar: AppBarWidget(
            title: AppStrings.get('home', 'recent', lang),
            onLanguagePressed: () => _showLanguageDialog(context),
            onNotificationPressed: () => _showNotificationsDialog(context),
            onProfilePressed: () {
              if (widget.onTabSelect != null) {
                widget.onTabSelect!(3);
              } else {
                Navigator.pushNamed(context, AppRouter.profile);
              }
            },
          ),
          body: Consumer2<PostProvider, CategoryProvider>(
            builder: (context, postProvider, categoryProvider, _) {
              if (postProvider.isLoading && postProvider.posts.isEmpty) {
                return LoadingIndicatorWidget(
                  message: AppStrings.get('common', 'loading', lang),
                );
              }

              if (postProvider.errorMessage != null && postProvider.posts.isEmpty) {
                return EmptyStateWidget(
                  icon: Icons.error_outline,
                  title: AppStrings.get('common', 'error', lang),
                  subtitle: postProvider.errorMessage ?? AppStrings.get('common', 'error', lang),
                  actionLabel: AppStrings.get('common', 'retry', lang),
                  onActionPressed: () {
                    postProvider.fetchPublishedPosts();
                    categoryProvider.fetchCategories();
                  },
                );
              }

              final displayedPosts = _filterPosts(postProvider.posts, categoryProvider);

              return RefreshIndicator(
                onRefresh: () async {
                  await postProvider.fetchPublishedPosts();
                  await categoryProvider.fetchCategories();
                },
                child: CustomScrollView(
                  physics: const AlwaysScrollableScrollPhysics(
                    parent: BouncingScrollPhysics(),
                  ),
                  slivers: [
                    // Search Bar at Top of Home Screen
                    SliverToBoxAdapter(
                      child: Padding(
                        padding: const EdgeInsets.fromLTRB(16, 12, 16, 8),
                        child: _buildSearchBar(),
                      ),
                    ),

                    // Recent Posts Marquee (continuous horizontal auto-scroll)
                    // Visible when not searching
                    if (_searchQuery.isEmpty && postProvider.posts.isNotEmpty)
                      SliverToBoxAdapter(
                        child: RecentPostsMarqueeWidget(posts: postProvider.posts),
                      ),

                    // Category Filter Pills (includes 'All' by default)
                    if (categoryProvider.categories.isNotEmpty)
                      SliverToBoxAdapter(
                        child: _buildCategoryChips(categoryProvider),
                      ),

                    // Results Header
                    SliverToBoxAdapter(
                      child: Padding(
                        padding: const EdgeInsets.fromLTRB(16, 12, 16, 6),
                        child: Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            Text(
                              _searchQuery.isNotEmpty
                                  ? 'Search Results (${displayedPosts.length})'
                                  : (_selectedCategoryId == 'all'
                                      ? 'All Posts (${displayedPosts.length})'
                                      : 'Filtered Posts (${displayedPosts.length})'),
                              style: const TextStyle(
                                color: Colors.white,
                                fontWeight: FontWeight.bold,
                                fontSize: 16,
                              ),
                            ),
                            if (_searchQuery.isNotEmpty || _selectedCategoryId != 'all')
                              TextButton(
                                onPressed: () {
                                  setState(() {
                                    _searchController.clear();
                                    _searchQuery = '';
                                    _selectedCategoryId = 'all';
                                  });
                                },
                                style: TextButton.styleFrom(
                                  padding: EdgeInsets.zero,
                                  minimumSize: const Size(50, 30),
                                  tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                                ),
                                child: const Text(
                                  'Reset',
                                  style: TextStyle(color: AppColors.cyan, fontSize: 12),
                                ),
                              ),
                          ],
                        ),
                      ),
                    ),

                    // Empty Search Results
                    if (displayedPosts.isEmpty)
                      SliverFillRemaining(
                        hasScrollBody: false,
                        child: Center(
                          child: Padding(
                            padding: const EdgeInsets.all(24.0),
                            child: EmptyStateWidget(
                              icon: Icons.search_off_rounded,
                              title: 'No Posts Found',
                              subtitle: _searchQuery.isNotEmpty
                                  ? 'No posts matching "$_searchQuery". Try searching by a different title or post code.'
                                  : 'No posts available in this category yet.',
                              actionLabel: 'Clear Filter',
                              onActionPressed: () {
                                setState(() {
                                  _searchController.clear();
                                  _searchQuery = '';
                                  _selectedCategoryId = 'all';
                                });
                              },
                            ),
                          ),
                        ),
                      )
                    else
                      // Posts List (Edge-to-edge full width)
                      SliverList(
                        delegate: SliverChildBuilderDelegate(
                          (context, index) {
                            final post = displayedPosts[index];
                            final isFav = postProvider.isFavorite(post.id);

                            return PostCardWidget(
                              post: post,
                              isFavorite: isFav,
                              onFavoritePressed: () async {
                                if (isFav) {
                                  await postProvider.removeFromFavorites(post.id);
                                } else {
                                  await postProvider.addToFavorites(post);
                                }
                              },
                              onTap: () {
                                Navigator.pushNamed(
                                  context,
                                  AppRouter.postDetails,
                                  arguments: post,
                                );
                              },
                            );
                          },
                          childCount: displayedPosts.length,
                        ),
                      ),

                    const SliverToBoxAdapter(
                      child: SizedBox(height: 80),
                    ),
                  ],
                ),
              );
            },
          ),
          bottomNavigationBar: widget.showBottomNav
              ? BottomNavigationWidget(
                  currentIndex: 0,
                  onTap: (index) {
                    if (widget.onTabSelect != null) {
                      widget.onTabSelect!(index);
                    }
                  },
                )
              : null,
        );
      },
    );
  }

  Widget _buildSearchBar() {
    return Container(
      decoration: BoxDecoration(
        color: const Color(0xFF131826),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: _searchQuery.isNotEmpty
              ? AppColors.cyan
              : AppColors.cyan.withValues(alpha: 0.35),
          width: 1.2,
        ),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.3),
            blurRadius: 8,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: TextField(
        controller: _searchController,
        style: const TextStyle(color: Colors.white, fontSize: 14),
        decoration: InputDecoration(
          hintText: 'Search by title or #code (e.g. #APP-01)...',
          hintStyle: TextStyle(
            color: AppColors.textSecondary.withValues(alpha: 0.7),
            fontSize: 13,
          ),
          prefixIcon: const Icon(Icons.search, color: AppColors.cyan, size: 20),
          suffixIcon: _searchQuery.isNotEmpty
              ? IconButton(
                  icon: const Icon(Icons.clear, color: AppColors.textSecondary, size: 18),
                  onPressed: () {
                    _searchController.clear();
                    setState(() {
                      _searchQuery = '';
                    });
                  },
                )
              : null,
          border: InputBorder.none,
          contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
        ),
        onChanged: (value) {
          setState(() {
            _searchQuery = value.trim();
          });
        },
      ),
    );
  }

  Widget _buildCategoryChips(CategoryProvider categoryProvider) {
    return Container(
      height: 40,
      margin: const EdgeInsets.symmetric(vertical: 4),
      child: ListView.builder(
        scrollDirection: Axis.horizontal,
        padding: const EdgeInsets.symmetric(horizontal: 14),
        itemCount: categoryProvider.categories.length,
        itemBuilder: (context, index) {
          final cat = categoryProvider.categories[index];
          final isSelected = _selectedCategoryId == cat.id;

          return Padding(
            padding: const EdgeInsets.symmetric(horizontal: 4),
            child: ChoiceChip(
              label: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  if (cat.id == 'all') ...[
                    Icon(
                      Icons.grid_view_rounded,
                      size: 14,
                      color: isSelected ? Colors.black : AppColors.cyan,
                    ),
                    const SizedBox(width: 4),
                  ],
                  Text(
                    cat.id == 'all' ? 'All' : cat.name,
                    style: TextStyle(
                      color: isSelected ? Colors.black : Colors.white70,
                      fontWeight: isSelected ? FontWeight.bold : FontWeight.w500,
                      fontSize: 12,
                    ),
                  ),
                ],
              ),
              selected: isSelected,
              selectedColor: AppColors.cyan,
              backgroundColor: const Color(0xFF101726),
              side: BorderSide(
                color: isSelected
                    ? AppColors.cyan
                    : AppColors.cyan.withValues(alpha: 0.25),
                width: 1,
              ),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(20),
              ),
              onSelected: (selected) {
                if (selected) {
                  setState(() {
                    _selectedCategoryId = cat.id;
                  });
                }
              },
            ),
          );
        },
      ),
    );
  }
}
