import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../../widgets/app_bar_widget.dart';
import '../../../widgets/bottom_navigation_widget.dart';
import '../../../widgets/loading_indicator_widget.dart';
import '../../../widgets/empty_state_widget.dart';
import '../../../core/routing/app_router.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/localization/app_strings.dart';
import '../../../providers/category_provider.dart';
import '../../../providers/settings_provider.dart';

class CategoriesScreen extends StatefulWidget {
  final bool showBottomNav;
  final ValueChanged<int>? onTabSelect;

  const CategoriesScreen({
    super.key,
    this.showBottomNav = true,
    this.onTabSelect,
  });

  @override
  State<CategoriesScreen> createState() => _CategoriesScreenState();
}

class _CategoriesScreenState extends State<CategoriesScreen> {
  @override
  void initState() {
    super.initState();
    // Fetch categories when screen loads
    WidgetsBinding.instance.addPostFrameCallback((_) {
      context.read<CategoryProvider>().fetchCategories();
      context.read<CategoryProvider>().listenToCategories();
    });
  }

  @override
  Widget build(BuildContext context) {
    return Consumer<SettingsProvider>(
      builder: (context, settings, _) {
        final lang = settings.language;

        return Scaffold(
          backgroundColor: Colors.transparent,
          appBar: AppBarWidget(
            title: AppStrings.get('categories', 'categories', lang),
            onProfilePressed: () {
              if (widget.onTabSelect != null) {
                widget.onTabSelect!(3);
              } else {
                Navigator.pushNamed(context, AppRouter.profile);
              }
            },
          ),
          body: Consumer<CategoryProvider>(
            builder: (context, categoryProvider, _) {
              if (categoryProvider.isLoading && categoryProvider.categories.isEmpty) {
                return LoadingIndicatorWidget(
                  message: AppStrings.get('common', 'loading', lang),
                );
              }

              if (categoryProvider.errorMessage != null && 
                  categoryProvider.categories.isEmpty) {
                return EmptyStateWidget(
                  icon: Icons.error_outline,
                  title: AppStrings.get('common', 'error', lang),
                  subtitle: categoryProvider.errorMessage ?? AppStrings.get('common', 'error', lang),
                  actionLabel: AppStrings.get('common', 'retry', lang),
                  onActionPressed: () {
                    categoryProvider.fetchCategories();
                  },
                );
              }

              if (categoryProvider.categories.isEmpty) {
                return EmptyStateWidget(
                  icon: Icons.folder_open,
                  title: AppStrings.get('categories', 'noCategoriesFound', lang),
                  subtitle: AppStrings.get('categories', 'noCategoriesFound', lang),
                  actionLabel: AppStrings.get('common', 'retry', lang),
                  onActionPressed: () {
                    categoryProvider.fetchCategories();
                  },
                );
              }

              return RefreshIndicator(
                onRefresh: () => categoryProvider.fetchCategories(),
                child: GridView.builder(
                  padding: const EdgeInsets.all(16),
                  gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                    crossAxisCount: 2,
                    childAspectRatio: 1,
                    crossAxisSpacing: 16,
                    mainAxisSpacing: 16,
                  ),
                  itemCount: categoryProvider.categories.length,
                  itemBuilder: (context, index) {
                    final category = categoryProvider.categories[index];
                    final postCount = categoryProvider.postCounts[category.id] ?? 0;
                    final isAll = category.id == 'all';
                    return Card(
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(16),
                        side: isAll
                            ? const BorderSide(color: AppColors.cyan, width: 1.5)
                            : BorderSide(color: AppColors.border.withValues(alpha: 0.5), width: 1),
                      ),
                      child: InkWell(
                        borderRadius: BorderRadius.circular(16),
                        onTap: () {
                          Navigator.pushNamed(
                            context,
                            AppRouter.categoryPosts,
                            arguments: category,
                          );
                        },
                        child: Padding(
                          padding: const EdgeInsets.all(16),
                          child: Column(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              Icon(
                                isAll ? Icons.grid_view_rounded : Icons.category,
                                size: 48,
                                color: isAll ? AppColors.cyan : AppColors.cyan.withValues(alpha: 0.8),
                              ),
                              const SizedBox(height: 12),
                              Text(
                                isAll ? 'All Posts' : category.name,
                                style: Theme.of(context).textTheme.titleMedium?.copyWith(
                                  fontWeight: isAll ? FontWeight.bold : FontWeight.w600,
                                  color: isAll ? AppColors.cyan : Colors.white,
                                ),
                                textAlign: TextAlign.center,
                                maxLines: 2,
                                overflow: TextOverflow.ellipsis,
                              ),
                              const SizedBox(height: 8),
                              Text(
                                '$postCount posts',
                                style: Theme.of(context).textTheme.bodySmall?.copyWith(
                                  color: isAll ? Colors.white70 : AppColors.textSecondary,
                                ),
                              ),
                            ],
                          ),
                        ),
                      ),
                    );
                  },
                ),
              );
            },
          ),
          bottomNavigationBar: widget.showBottomNav
              ? BottomNavigationWidget(
                  currentIndex: 1,
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
}
