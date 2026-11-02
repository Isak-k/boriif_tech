import 'package:flutter/material.dart';
import '../core/theme/app_colors.dart';
import '../models/post_model.dart';
import 'cached_app_image.dart';

class PostCardWidget extends StatelessWidget {
  final Post post;
  final bool isFavorite;
  final VoidCallback? onTap;
  final VoidCallback? onFavoritePressed;

  const PostCardWidget({
    super.key,
    required this.post,
    this.isFavorite = false,
    this.onTap,
    this.onFavoritePressed,
  });

  @override
  Widget build(BuildContext context) {
    return Card(
      margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      elevation: 2,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(12),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Image section with automatic device disk caching
            _buildImageSection(),
            
            // Content section
            Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Title and favorite
                  _buildTitleSection(context),
                  const SizedBox(height: 8),
                  
                  // Description
                  _buildDescription(context),
                  const SizedBox(height: 12),
                  
                  // Meta information
                  _buildMetaSection(context),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildImageSection() {
    if (post.imageUrl == null || post.imageUrl!.isEmpty) {
      return const SizedBox.shrink();
    }

    return Container(
      constraints: const BoxConstraints(minHeight: 140, maxHeight: 220),
      width: double.infinity,
      decoration: const BoxDecoration(
        color: Color(0xFF0F1522),
        borderRadius: BorderRadius.only(
          topLeft: Radius.circular(12),
          topRight: Radius.circular(12),
        ),
      ),
      child: ClipRRect(
        borderRadius: const BorderRadius.only(
          topLeft: Radius.circular(12),
          topRight: Radius.circular(12),
        ),
        child: CachedAppImage(
          imageUrl: post.imageUrl,
          width: double.infinity,
          fit: BoxFit.cover,
          placeholderIcon: _getTypeIcon(post.postType),
        ),
      ),
    );
  }

  Widget _buildTitleSection(BuildContext context) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Expanded(
          child: Text(
            post.title,
            style: Theme.of(context).textTheme.titleLarge,
            maxLines: 2,
            overflow: TextOverflow.ellipsis,
          ),
        ),
        IconButton(
          icon: Icon(
            isFavorite ? Icons.favorite : Icons.favorite_border,
            color: isFavorite ? AppColors.error : AppColors.textSecondary,
          ),
          onPressed: onFavoritePressed,
          padding: EdgeInsets.zero,
          constraints: const BoxConstraints(),
        ),
      ],
    );
  }

  Widget _buildDescription(BuildContext context) {
    return Text(
      post.shortDescription,
      style: Theme.of(context).textTheme.bodySmall,
      maxLines: 2,
      overflow: TextOverflow.ellipsis,
    );
  }

  Widget _buildMetaSection(BuildContext context) {
    return Row(
      children: [
        // Post code badge
        if (post.code.isNotEmpty) ...[
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 7, vertical: 3),
            decoration: BoxDecoration(
              color: AppColors.cyan.withValues(alpha: 0.15),
              borderRadius: BorderRadius.circular(4),
              border: Border.all(
                color: AppColors.cyan.withValues(alpha: 0.35),
                width: 0.8,
              ),
            ),
            child: Text(
              '#${post.code}',
              style: const TextStyle(
                color: AppColors.cyan,
                fontSize: 10,
                fontWeight: FontWeight.bold,
                letterSpacing: 0.5,
              ),
            ),
          ),
          const SizedBox(width: 8),
        ],

        // Post type badge
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
          decoration: BoxDecoration(
            color: _getTypeColor(post.postType).withValues(alpha: 0.15),
            borderRadius: BorderRadius.circular(4),
          ),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(
                _getTypeIcon(post.postType),
                size: 14,
                color: _getTypeColor(post.postType),
              ),
              const SizedBox(width: 4),
              Text(
                post.postType.toUpperCase(),
                style: TextStyle(
                  color: _getTypeColor(post.postType),
                  fontSize: 10,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ],
          ),
        ),
        const Spacer(),

        // Views count
        Row(
          children: [
            const Icon(
              Icons.visibility_outlined,
              size: 14,
              color: AppColors.textSecondary,
            ),
            const SizedBox(width: 4),
            Text(
              '${post.viewsCount}',
              style: Theme.of(context).textTheme.bodySmall,
            ),
          ],
        ),
        const SizedBox(width: 10),

        // Likes count
        Row(
          children: [
            Icon(
              isFavorite ? Icons.favorite : Icons.favorite_border,
              size: 14,
              color: isFavorite ? AppColors.error : AppColors.textSecondary,
            ),
            const SizedBox(width: 4),
            Text(
              '${post.likesCount}',
              style: Theme.of(context).textTheme.bodySmall,
            ),
          ],
        ),
        const SizedBox(width: 10),

        // Date
        Row(
          children: [
            const Icon(
              Icons.access_time,
              size: 14,
              color: AppColors.textSecondary,
            ),
            const SizedBox(width: 4),
            Text(
              _formatDate(post.publishedAt ?? post.createdAt),
              style: Theme.of(context).textTheme.bodySmall,
            ),
          ],
        ),
      ],
    );
  }

  Color _getTypeColor(String type) {
    switch (type.toLowerCase()) {
      case 'app':
        return AppColors.cyan;
      case 'article':
        return AppColors.purple;
      case 'job':
        return AppColors.accent;
      default:
        return AppColors.textSecondary;
    }
  }

  IconData _getTypeIcon(String type) {
    switch (type.toLowerCase()) {
      case 'app':
        return Icons.apps;
      case 'article':
        return Icons.article;
      case 'job':
        return Icons.work;
      default:
        return Icons.insert_drive_file;
    }
  }

  String _formatDate(DateTime date) {
    final now = DateTime.now();
    final difference = now.difference(date);

    if (difference.inDays > 365) {
      return '${(difference.inDays / 365).floor()}y ago';
    } else if (difference.inDays > 30) {
      return '${(difference.inDays / 30).floor()}mo ago';
    } else if (difference.inDays > 0) {
      return '${difference.inDays}d ago';
    } else if (difference.inHours > 0) {
      return '${difference.inHours}h ago';
    } else if (difference.inMinutes > 0) {
      return '${difference.inMinutes}m ago';
    } else {
      return 'just now';
    }
  }
}
