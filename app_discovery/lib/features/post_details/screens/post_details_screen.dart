import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../../core/theme/app_colors.dart';
import '../../../providers/post_provider.dart';
import '../../../services/url_launcher_service.dart';
import '../../../widgets/loading_indicator_widget.dart';
import '../../../widgets/empty_state_widget.dart';
import '../../../widgets/cached_app_image.dart';

class PostDetailsScreen extends StatefulWidget {
  final String? postId;

  const PostDetailsScreen({
    Key? key,
    this.postId,
  }) : super(key: key);

  @override
  State<PostDetailsScreen> createState() => _PostDetailsScreenState();
}

class _PostDetailsScreenState extends State<PostDetailsScreen> {

  @override
  void initState() {
    super.initState();
    if (widget.postId != null) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        _loadPostDetails();
      });
    }
  }

  Future<void> _loadPostDetails() async {
    final postProvider = context.read<PostProvider>();
    await postProvider.fetchPostById(widget.postId!);
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
          if (postProvider.isLoading) {
            return const LoadingIndicatorWidget(message: 'Loading post...');
          }

          if (postProvider.errorMessage != null) {
            return EmptyStateWidget(
              icon: Icons.error_outline,
              title: 'Error Loading Post',
              subtitle: postProvider.errorMessage ?? 'An error occurred',
              actionLabel: 'Go Back',
              onActionPressed: () {
                Navigator.pop(context);
              },
            );
          }

          if (postProvider.selectedPost == null) {
            return EmptyStateWidget(
              icon: Icons.article_outlined,
              title: 'Post Not Found',
              subtitle: 'The post you are looking for does not exist or has been unpublished.',
              actionLabel: 'Go Back',
              onActionPressed: () {
                Navigator.pop(context);
              },
            );
          }

          final post = postProvider.selectedPost!;
          final isFavorite = postProvider.isFavorite(post.id);

          return SingleChildScrollView(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Header image
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
                      _buildShortDescription(post),
                      const SizedBox(height: 16),

                      // Full description
                      _buildFullDescription(post),
                      const SizedBox(height: 24),

                      // Action buttons (Get it now, Visit website, etc.)
                      _buildActionButtons(post),
                      const SizedBox(height: 24),
                    ],
                  ),
                ),
              ],
            ),
          );
        },
      ),
    );
  }

  Widget _buildHeaderImage(dynamic post) {
    if (post.imageUrl == null || (post.imageUrl as String).isEmpty) {
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

  Widget _buildTitleSection(dynamic post, bool isFavorite, PostProvider postProvider) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Expanded(
          child: Text(
            post.title,
            style: Theme.of(context).textTheme.displayMedium?.copyWith(
              fontWeight: FontWeight.bold,
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

  Widget _buildMetaSection(dynamic post) {
    final publishDate = post.publishedAt?.toString().split(' ')[0] ?? 'Unknown';
    final postCode = post.code as String? ?? '';
    
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

  Widget _buildShortDescription(dynamic post) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Overview',
          style: Theme.of(context).textTheme.headlineSmall?.copyWith(
            fontWeight: FontWeight.bold,
          ),
        ),
        const SizedBox(height: 8),
        Text(
          post.shortDescription,
          style: Theme.of(context).textTheme.titleMedium?.copyWith(
            height: 1.4,
          ),
        ),
      ],
    );
  }

  Widget _buildFullDescription(dynamic post) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Description',
          style: Theme.of(context).textTheme.headlineSmall?.copyWith(
            fontWeight: FontWeight.bold,
          ),
        ),
        const SizedBox(height: 8),
        Text(
          post.description,
          style: Theme.of(context).textTheme.bodyLarge?.copyWith(
            height: 1.5,
          ),
        ),
      ],
    );
  }

  Widget _buildActionButtons(dynamic post) {
    final buttons = <Widget>[];

    // Get it now button for app posts
    if (post.postType == 'app' && post.playStoreUrl != null && post.playStoreUrl!.isNotEmpty) {
      buttons.add(_buildGetItNowButton(post.playStoreUrl!));
      buttons.add(const SizedBox(height: 12));
    }

    // Visit website button for article/job posts
    if ((post.postType == 'article' || post.postType == 'job') && 
        post.externalUrl != null && post.externalUrl!.isNotEmpty) {
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
        onPressed: () async {
          final success = await UrlLauncherService.launchPlayStoreUrl(
            playStoreUrl,
            context,
          );
          
          if (success) {
            ScaffoldMessenger.of(context).showSnackBar(
              const SnackBar(
                content: Text('Opening Google Play Store...'),
                duration: Duration(seconds: 2),
              ),
            );
          }
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
        onPressed: () async {
          final success = await UrlLauncherService.launchExternalUrl(
            externalUrl,
            context,
          );
          
          if (success) {
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(
                content: Text('Opening $label...'),
                duration: const Duration(seconds: 2),
              ),
            );
          }
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