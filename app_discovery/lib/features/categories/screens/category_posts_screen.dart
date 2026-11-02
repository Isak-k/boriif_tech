import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../../widgets/loading_indicator_widget.dart';
import '../../../widgets/empty_state_widget.dart';
import '../../../widgets/post_card_widget.dart';
import '../../../core/routing/app_router.dart';
import '../../../core/localization/app_strings.dart';
import '../../../models/category_model.dart';
import '../../../providers/post_provider.dart';
import '../../../providers/settings_provider.dart';

class CategoryPostsScreen extends StatefulWidget {
  final Category category;

  const CategoryPostsScreen({
    super.key,
    required this.category,
  });

  @override
  State<CategoryPostsScreen> createState() => _CategoryPostsScreenState();
}

class _CategoryPostsScreenState extends State<CategoryPostsScreen> {
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      context.read<PostProvider>().fetchPostsByCategory(widget.category.id);
    });
  }

  @override
  Widget build(BuildContext context) {
    return Consumer<SettingsProvider>(
      builder: (context, settings, _) {
        final lang = settings.language;

        return Scaffold(
          backgroundColor: Colors.transparent,
          appBar: AppBar(
            title: Text(widget.category.id == 'all' ? 'All Posts' : widget.category.name),
            leading: IconButton(
              icon: const Icon(Icons.arrow_back),
              onPressed: () => Navigator.pop(context),
            ),
          ),
          body: Consumer<PostProvider>(
            builder: (context, postProvider, _) {
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
                    postProvider.fetchPostsByCategory(widget.category.id);
                  },
                );
              }

              if (postProvider.posts.isEmpty) {
                return EmptyStateWidget(
                  icon: Icons.article_outlined,
                  title: AppStrings.get('common', 'noResults', lang),
                  subtitle: 'No posts found in ${widget.category.name}',
                  actionLabel: AppStrings.get('common', 'retry', lang),
                  onActionPressed: () {
                    postProvider.fetchPostsByCategory(widget.category.id);
                  },
                );
              }

              return RefreshIndicator(
                onRefresh: () => postProvider.fetchPostsByCategory(widget.category.id),
                child: ListView.builder(
                  padding: const EdgeInsets.only(top: 6, bottom: 24),
                  itemCount: postProvider.posts.length,
                  itemBuilder: (context, index) {
                    final post = postProvider.posts[index];
                    return PostCardWidget(
                      post: post,
                      isFavorite: postProvider.isFavorite(post.id),
                      onTap: () {
                        Navigator.pushNamed(
                          context,
                          AppRouter.postDetails,
                          arguments: post,
                        );
                      },
                      onFavoritePressed: () async {
                        if (postProvider.isFavorite(post.id)) {
                          await postProvider.removeFromFavorites(post.id);
                        } else {
                          await postProvider.addToFavorites(post);
                        }
                      },
                    );
                  },
                ),
              );
            },
          ),
        );
      },
    );
  }
}
