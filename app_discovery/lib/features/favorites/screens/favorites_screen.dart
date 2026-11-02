import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../../widgets/app_bar_widget.dart';
import '../../../widgets/bottom_navigation_widget.dart';
import '../../../widgets/post_card_widget.dart';
import '../../../widgets/empty_state_widget.dart';
import '../../../core/routing/app_router.dart';
import '../../../core/localization/app_strings.dart';
import '../../../providers/post_provider.dart';
import '../../../providers/settings_provider.dart';

class FavoritesScreen extends StatefulWidget {
  final bool showBottomNav;
  final ValueChanged<int>? onTabSelect;

  const FavoritesScreen({
    super.key,
    this.showBottomNav = true,
    this.onTabSelect,
  });

  @override
  State<FavoritesScreen> createState() => _FavoritesScreenState();
}

class _FavoritesScreenState extends State<FavoritesScreen> {
  @override
  Widget build(BuildContext context) {
    return Consumer<SettingsProvider>(
      builder: (context, settings, _) {
        final lang = settings.language;

        return Scaffold(
          backgroundColor: Colors.transparent,
          appBar: AppBarWidget(
            title: AppStrings.get('navigation', 'favorites', lang),
            onProfilePressed: () {
              if (widget.onTabSelect != null) {
                widget.onTabSelect!(3);
              } else {
                Navigator.pushNamed(context, AppRouter.profile);
              }
            },
          ),
          body: Consumer<PostProvider>(
            builder: (context, postProvider, _) {
              if (postProvider.favoritePosts.isEmpty) {
                return EmptyStateWidget(
                  icon: Icons.favorite_border,
                  title: AppStrings.get('common', 'noResults', lang),
                  subtitle: AppStrings.get('common', 'noResults', lang),
                  actionLabel: AppStrings.get('navigation', 'home', lang),
                  onActionPressed: () {
                    if (widget.onTabSelect != null) {
                      widget.onTabSelect!(0);
                    } else {
                      Navigator.pushNamed(context, AppRouter.home);
                    }
                  },
                );
              }

              return ListView.builder(
                padding: const EdgeInsets.symmetric(vertical: 8),
                itemCount: postProvider.favoritePosts.length,
                itemBuilder: (context, index) {
                  final post = postProvider.favoritePosts[index];
                  return PostCardWidget(
                    post: post,
                    isFavorite: true,
                    onTap: () {
                      Navigator.pushNamed(
                        context,
                        AppRouter.postDetails,
                        arguments: post.id,
                      );
                    },
                    onFavoritePressed: () async {
                      await postProvider.removeFromFavorites(post.id);
                      if (context.mounted) {
                        ScaffoldMessenger.of(context).showSnackBar(
                          SnackBar(
                            content: Text(
                              AppStrings.get('common', 'success', lang),
                            ),
                          ),
                        );
                      }
                    },
                  );
                },
              );
            },
          ),
          bottomNavigationBar: widget.showBottomNav
              ? BottomNavigationWidget(
                  currentIndex: 2,
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
