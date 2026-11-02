import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../../core/theme/app_colors.dart';
import '../../../models/post_model.dart';
import '../../../providers/post_provider.dart';
import '../../../services/url_launcher_service.dart';
import '../../../widgets/loading_indicator_widget.dart';
import '../../../widgets/empty_state_widget.dart';
import '../../../widgets/cached_app_image.dart';

class PostDetailsScreen extends StatefulWidget {
  final String? postId;
  final Post? initialPost;

  const PostDetailsScreen({
    super.key,
    this.postId,
    this.initialPost,
  });

  @override
  State<PostDetailsScreen> createState() => _PostDetailsScreenState();
}

class _PostDetailsScreenState extends State<PostDetailsScreen> {
  Post? _localPost;

  @override
  void initState() {
    super.initState();

    // 1. If an initial post was passed, use it immediately (0ms delay)
    if (widget.initialPost != null) {
      _localPost = widget.initialPost;
    }

    // 2. Schedule background initialization & view recording
    WidgetsBinding.instance.addPostFrameCallback((_) {
      final postProvider = context.read<PostProvider>();

      if (_localPost == null && widget.postId != null) {
        // Try locating in existing provider memory first
        final inMemory = postProvider.posts.where((p) => p.id == widget.postId).firstOrNull ??
            postProvider.favoritePosts.where((p) => p.id == widget.postId).firstOrNull;

        if (inMemory != null) {
          setState(() {
            _localPost = inMemory;
          });
          postProvider.setSelectedPost(inMemory);
          postProvider.recordViewSilently(widget.postId!);
          return;
        }

        // If not found in memory, fetch with provider
        postProvider.fetchPostById(widget.postId!);
      } else if (_localPost != null) {
        postProvider.setSelectedPost(_localPost!);
        postProvider.recordViewSilently(_localPost!.id);
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.transparent,
      appBar: AppBar(
        title: const Text('Post Details'),
        leading: IconButton(
          icon: const Icon(Icons.arrow_back),
          onPressed: () => Navigator.pop(context),
        ),
      ),
      body: Consumer<PostProvider>(
        builder: (context, postProvider, _) {
          // Resolve post: prefer provider's selected post, fall back to initial local post
          final post = postProvider.selectedPost ?? _localPost;

          // If we already have post data, render it immediately without showing full-screen loader!
          if (post != null) {
            final isFavorite = postProvider.isFavorite(post.id);
            return _buildPostContent(context, post, isFavorite, postProvider);
          }

          if (postProvider.isLoading) {
            return const LoadingIndicatorWidget(message: 'Loading post...');
          }

          if (postProvider.errorMessage != null) {
            return EmptyStateWidget(
              icon: Icons.error_outline,
              title: 'Error Loading Post',
              subtitle: postProvider.errorMessage ?? 'An error occurred',
              actionLabel: 'Go Back',
              onActionPressed: () => Navigator.pop(context),
            );
          }

          return EmptyStateWidget(
            icon: Icons.article_outlined,
            title: 'Post Not Found',
            subtitle: 'The post you are looking for does not exist or has been unpublished.',
            actionLabel: 'Go Back',
            onActionPressed: () => Navigator.pop(context),
          );
        },
      ),
    );
  }

  Widget _buildPostContent(
    BuildContext context,
    Post post,
    bool isFavorite,
    PostProvider postProvider,
  ) {
    return SingleChildScrollView(
      physics: const BouncingScrollPhysics(),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Full-width header image
          _buildHeaderImage(post),

          Padding(
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Title and favorite button
                _buildTitleSection(post, isFavorite, postProvider),
                const SizedBox(height: 16),

                // Meta information (category, date, views)
                _buildMetaSection(post),
                const SizedBox(height: 24),

                // Short description
                if (post.shortDescription.isNotEmpty) ...[
                  _buildShortDescription(post),
                  const SizedBox(height: 16),
                ],

                // Full description
                if (post.description.isNotEmpty) ...[
                  _buildFullDescription(post),
                  const SizedBox(height: 24),
                ],

                // Action buttons (Get it now directly, Visit website, etc.)
                _buildActionButtons(post),
                const SizedBox(height: 36),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildHeaderImage(Post post) {
    if (post.imageUrl == null || post.imageUrl!.isEmpty) {
      return const SizedBox.shrink();
    }

    return Container(
      width: double.infinity,
      constraints: const BoxConstraints(minHeight: 180, maxHeight: 420),
      decoration: const BoxDecoration(
        color: Color(0xFF0B1019),
        borderRadius: BorderRadius.only(
          bottomLeft: Radius.circular(16),
          bottomRight: Radius.circular(16),
        ),
      ),
      child: ClipRRect(
        borderRadius: const BorderRadius.only(
          bottomLeft: Radius.circular(16),
          bottomRight: Radius.circular(16),
        ),
        child: CachedAppImage(
          imageUrl: post.imageUrl,
          width: double.infinity,
          fit: BoxFit.contain,
          placeholderIcon: Icons.image_outlined,
        ),
      ),
    );
  }

  Widget _buildTitleSection(Post post, bool isFavorite, PostProvider postProvider) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Expanded(
          child: Text(
            post.title,
            style: Theme.of(context).textTheme.displayMedium?.copyWith(
                  fontWeight: FontWeight.bold,
                  fontSize: 22,
                  height: 1.3,
                  color: Colors.white,
                ),
          ),
        ),
        const SizedBox(width: 8),
        InkWell(
          borderRadius: BorderRadius.circular(20),
          onTap: () async {
            if (isFavorite) {
              await postProvider.removeFromFavorites(post.id);
            } else {
              await postProvider.addToFavorites(post);
            }
          },
          child: Container(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
            decoration: BoxDecoration(
              color: isFavorite ? AppColors.error.withValues(alpha: 0.15) : AppColors.elevatedSurface,
              borderRadius: BorderRadius.circular(20),
              border: Border.all(
                color: isFavorite ? AppColors.error : AppColors.border,
                width: 1,
              ),
            ),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Icon(
                  isFavorite ? Icons.favorite : Icons.favorite_border,
                  color: isFavorite ? AppColors.error : AppColors.textSecondary,
                  size: 20,
                ),
                const SizedBox(width: 6),
                Text(
                  '${post.likesCount}',
                  style: TextStyle(
                    color: isFavorite ? AppColors.error : Colors.white,
                    fontWeight: FontWeight.bold,
                    fontSize: 14,
                  ),
                ),
              ],
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildMetaSection(Post post) {
    final publishDate = post.publishedAt?.toString().split(' ')[0] ??
        post.createdAt.toString().split(' ')[0];
    final postCode = post.code;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            // Post type badge
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
              decoration: BoxDecoration(
                color: _getTypeColor(post.postType),
                borderRadius: BorderRadius.circular(20),
              ),
              child: Text(
                post.postType.toUpperCase(),
                style: const TextStyle(
                  color: Colors.white,
                  fontSize: 12,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ),
            if (postCode.isNotEmpty) ...[
              const SizedBox(width: 8),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                decoration: BoxDecoration(
                  color: AppColors.cyan.withValues(alpha: 0.15),
                  borderRadius: BorderRadius.circular(20),
                  border: Border.all(
                    color: AppColors.cyan.withValues(alpha: 0.4),
                  ),
                ),
                child: Text(
                  '#$postCode',
                  style: const TextStyle(
                    color: AppColors.cyan,
                    fontSize: 12,
                    fontWeight: FontWeight.bold,
                    letterSpacing: 0.5,
                  ),
                ),
              ),
            ],
          ],
        ),
        const SizedBox(height: 10),

        // Date, views and likes
        Wrap(
          spacing: 16,
          runSpacing: 8,
          children: [
            Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                const Icon(Icons.calendar_today, size: 15, color: AppColors.textSecondary),
                const SizedBox(width: 4),
                Text(
                  'Published $publishDate',
                  style: Theme.of(context).textTheme.bodySmall?.copyWith(
                        color: AppColors.textSecondary,
                      ),
                ),
              ],
            ),
            Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                const Icon(Icons.visibility, size: 15, color: AppColors.cyan),
                const SizedBox(width: 4),
                Text(
                  '${post.viewsCount} views',
                  style: Theme.of(context).textTheme.bodySmall?.copyWith(
                        color: AppColors.cyan,
                        fontWeight: FontWeight.w600,
                      ),
                ),
              ],
            ),
            Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                const Icon(Icons.favorite, size: 15, color: AppColors.error),
                const SizedBox(width: 4),
                Text(
                  '${post.likesCount} likes',
                  style: Theme.of(context).textTheme.bodySmall?.copyWith(
                        color: AppColors.error,
                        fontWeight: FontWeight.w600,
                      ),
                ),
              ],
            ),
          ],
        ),
      ],
    );
  }

  Widget _buildShortDescription(Post post) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Overview',
          style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                fontWeight: FontWeight.bold,
                fontSize: 18,
                color: Colors.white,
              ),
        ),
        const SizedBox(height: 8),
        Text(
          post.shortDescription,
          style: Theme.of(context).textTheme.titleMedium?.copyWith(
                height: 1.4,
                color: Colors.white70,
              ),
        ),
      ],
    );
  }

  Widget _buildFullDescription(Post post) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Description',
          style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                fontWeight: FontWeight.bold,
                fontSize: 18,
                color: Colors.white,
              ),
        ),
        const SizedBox(height: 8),
        Text(
          post.description,
          style: Theme.of(context).textTheme.bodyLarge?.copyWith(
                height: 1.5,
                color: Colors.white.withValues(alpha: 0.85),
              ),
        ),
      ],
    );
  }

  Widget _buildActionButtons(Post post) {
    final buttons = <Widget>[];

    // Get it now button for app posts (direct 1-tap Google Play Store opening)
    if (post.postType == 'app' && post.playStoreUrl != null && post.playStoreUrl!.isNotEmpty) {
      buttons.add(_buildGetItNowButton(post.playStoreUrl!));
      buttons.add(const SizedBox(height: 12));
    }

    // Direct button for article/job posts
    if ((post.postType == 'article' || post.postType == 'job') &&
        post.externalUrl != null &&
        post.externalUrl!.isNotEmpty) {
      buttons.add(_buildVisitWebsiteButton(post.externalUrl!, post.postType));
    }

    return buttons.isEmpty
        ? const SizedBox.shrink()
        : Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'Actions',
                style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                      fontWeight: FontWeight.bold,
                      fontSize: 18,
                      color: Colors.white,
                    ),
              ),
              const SizedBox(height: 12),
              ...buttons,
            ],
          );
  }

  Widget _buildGetItNowButton(String playStoreUrl) {
    return SizedBox(
      width: double.infinity,
      child: ElevatedButton.icon(
        onPressed: () {
          // Direct 1-tap Google Play Store launch without intermediate dialogs or snackbars
          UrlLauncherService.launchPlayStoreUrl(
            playStoreUrl,
            context,
          );
        },
        icon: const Icon(Icons.shop, size: 24),
        label: const Text(
          'Get it now',
          style: TextStyle(
            fontSize: 18,
            fontWeight: FontWeight.bold,
          ),
        ),
        style: ElevatedButton.styleFrom(
          backgroundColor: Colors.green,
          foregroundColor: Colors.white,
          padding: const EdgeInsets.symmetric(vertical: 16),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(12),
          ),
        ),
      ),
    );
  }

  Widget _buildVisitWebsiteButton(String externalUrl, String postType) {
    String label = 'Get it now';
    IconData icon = Icons.download_rounded;

    switch (postType) {
      case 'article':
        label = 'Read Full Article';
        icon = Icons.article;
        break;
      default:
        label = 'Get it now';
        icon = Icons.open_in_new_rounded;
    }

    return SizedBox(
      width: double.infinity,
      child: ElevatedButton.icon(
        onPressed: () {
          UrlLauncherService.launchExternalUrl(
            externalUrl,
            context,
          );
        },
        icon: Icon(icon, size: 20),
        label: Text(
          label,
          style: const TextStyle(
            fontSize: 16,
            fontWeight: FontWeight.w600,
          ),
        ),
        style: ElevatedButton.styleFrom(
          backgroundColor: AppColors.cyan,
          foregroundColor: Colors.white,
          padding: const EdgeInsets.symmetric(vertical: 14),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(10),
          ),
        ),
      ),
    );
  }

  Color _getTypeColor(String postType) {
    switch (postType) {
      case 'app':
        return Colors.green;
      case 'article':
        return Colors.blue;
      case 'job':
        return Colors.orange;
      default:
        return AppColors.textSecondary;
    }
  }
}
