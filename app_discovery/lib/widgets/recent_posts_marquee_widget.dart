import 'dart:async';
import 'package:flutter/material.dart';
import '../core/theme/app_colors.dart';
import '../models/post_model.dart';
import '../core/routing/app_router.dart';
import 'cached_app_image.dart';

/// Horizontal widget displaying recent posts that scrolls horizontally continuously.
/// User can freely tap to open a post, or swipe manually, with auto-scroll pausing on touch.
class RecentPostsMarqueeWidget extends StatefulWidget {
  final List<Post> posts;

  const RecentPostsMarqueeWidget({
    super.key,
    required this.posts,
  });

  @override
  State<RecentPostsMarqueeWidget> createState() => _RecentPostsMarqueeWidgetState();
}

class _RecentPostsMarqueeWidgetState extends State<RecentPostsMarqueeWidget> {
  late final ScrollController _scrollController;
  Timer? _autoScrollTimer;
  Timer? _resumeTimer;
  bool _isUserInteracting = false;

  @override
  void initState() {
    super.initState();
    _scrollController = ScrollController();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _startAutoScroll();
    });
  }

  @override
  void dispose() {
    _autoScrollTimer?.cancel();
    _resumeTimer?.cancel();
    _scrollController.dispose();
    super.dispose();
  }

  void _startAutoScroll() {
    _autoScrollTimer?.cancel();
    // Continuous subtle scrolling: 1 pixel every 35 milliseconds (~28fps continuous marquee)
    _autoScrollTimer = Timer.periodic(const Duration(milliseconds: 35), (timer) {
      if (!_scrollController.hasClients || _isUserInteracting) return;

      final maxScroll = _scrollController.position.maxScrollExtent;
      final currentScroll = _scrollController.offset;

      if (currentScroll >= maxScroll - 1) {
        // Wrap smoothly back to start for continuous looping
        _scrollController.jumpTo(0);
      } else {
        _scrollController.jumpTo(currentScroll + 1.0);
      }
    });
  }

  void _onUserInteractionStart() {
    _isUserInteracting = true;
    _resumeTimer?.cancel();
  }

  void _onUserInteractionEnd() {
    _resumeTimer?.cancel();
    // Resume auto-scrolling 2.5 seconds after user finishes touching
    _resumeTimer = Timer(const Duration(milliseconds: 2500), () {
      if (mounted) {
        setState(() {
          _isUserInteracting = false;
        });
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    if (widget.posts.isEmpty) {
      return const SizedBox.shrink();
    }

    // Take up to 10 recent posts
    final recentPosts = widget.posts.take(10).toList();
    // Duplicate list items to create a seamless infinite loop feeling
    final displayList = recentPosts.length > 2
        ? [...recentPosts, ...recentPosts, ...recentPosts]
        : recentPosts;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // Section Header
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
          child: Row(
            children: [
              Container(
                width: 8,
                height: 8,
                decoration: const BoxDecoration(
                  color: AppColors.cyan,
                  shape: BoxShape.circle,
                  boxShadow: [
                    BoxShadow(
                      color: AppColors.cyan,
                      blurRadius: 6,
                      spreadRadius: 1,
                    ),
                  ],
                ),
              ),
              const SizedBox(width: 8),
              const Text(
                'Recent Posts',
                style: TextStyle(
                  color: Colors.white,
                  fontWeight: FontWeight.bold,
                  fontSize: 15,
                  letterSpacing: 0.3,
                ),
              ),
              const Spacer(),
              Text(
                'Continuous feed',
                style: TextStyle(
                  color: AppColors.textSecondary.withValues(alpha: 0.7),
                  fontSize: 11,
                  fontStyle: FontStyle.italic,
                ),
              ),
            ],
          ),
        ),

        // Continuous horizontal list
        SizedBox(
          height: 148,
          child: NotificationListener<ScrollNotification>(
            onNotification: (notification) {
              if (notification is ScrollStartNotification) {
                _onUserInteractionStart();
              } else if (notification is ScrollEndNotification) {
                _onUserInteractionEnd();
              }
              return false;
            },
            child: ListView.builder(
              controller: _scrollController,
              scrollDirection: Axis.horizontal,
              physics: const BouncingScrollPhysics(),
              padding: const EdgeInsets.symmetric(horizontal: 12),
              itemCount: displayList.length,
              itemBuilder: (context, index) {
                final post = displayList[index];
                return _buildRecentCard(context, post);
              },
            ),
          ),
        ),
        const SizedBox(height: 6),
      ],
    );
  }

  Widget _buildRecentCard(BuildContext context, Post post) {
    return Container(
      width: 210,
      margin: const EdgeInsets.symmetric(horizontal: 5, vertical: 4),
      decoration: BoxDecoration(
        color: const Color(0xFF101622),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: AppColors.cyan.withValues(alpha: 0.22),
          width: 1,
        ),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.3),
            blurRadius: 6,
            offset: const Offset(0, 3),
          ),
        ],
      ),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          borderRadius: BorderRadius.circular(12),
          onTap: () {
            Navigator.pushNamed(
              context,
              AppRouter.postDetails,
              arguments: post.id,
            );
          },
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Image container with overlays
              Stack(
                children: [
                  Container(
                    height: 78,
                    width: double.infinity,
                    decoration: const BoxDecoration(
                      borderRadius: BorderRadius.vertical(top: Radius.circular(11)),
                    ),
                    child: CachedAppImage(
                      imageUrl: post.imageUrl,
                      width: double.infinity,
                      height: 78,
                      fit: BoxFit.cover,
                      borderRadius: const BorderRadius.vertical(top: Radius.circular(11)),
                      placeholderIcon: Icons.image_outlined,
                    ),
                  ),

                  // Post Code Badge (Top-left)
                  if (post.code.isNotEmpty)
                    Positioned(
                      top: 5,
                      left: 5,
                      child: Container(
                        padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                        decoration: BoxDecoration(
                          color: const Color(0xDD000000),
                          borderRadius: BorderRadius.circular(4),
                          border: Border.all(
                            color: AppColors.cyan.withValues(alpha: 0.8),
                            width: 0.8,
                          ),
                        ),
                        child: Text(
                          '#${post.code}',
                          style: const TextStyle(
                            color: AppColors.cyan,
                            fontSize: 9,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ),
                    ),

                  // Post Type Badge (Top-right)
                  Positioned(
                    top: 5,
                    right: 5,
                    child: Container(
                      padding: const EdgeInsets.symmetric(horizontal: 5, vertical: 2),
                      decoration: BoxDecoration(
                        color: _getTypeColor(post.postType).withValues(alpha: 0.85),
                        borderRadius: BorderRadius.circular(4),
                      ),
                      child: Text(
                        post.postType.toUpperCase(),
                        style: const TextStyle(
                          color: Colors.white,
                          fontSize: 8,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ),
                  ),
                ],
              ),

              // Title and metrics
              Expanded(
                child: Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 6),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text(
                        post.title,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: const TextStyle(
                          color: Colors.white,
                          fontSize: 12,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Row(
                            children: [
                              const Icon(
                                Icons.visibility_outlined,
                                size: 12,
                                color: AppColors.cyan,
                              ),
                              const SizedBox(width: 3),
                              Text(
                                '${post.viewsCount}',
                                style: const TextStyle(
                                  color: AppColors.cyan,
                                  fontSize: 10,
                                  fontWeight: FontWeight.w600,
                                ),
                              ),
                            ],
                          ),
                          Row(
                            children: [
                              const Icon(
                                Icons.favorite,
                                size: 12,
                                color: AppColors.error,
                              ),
                              const SizedBox(width: 3),
                              Text(
                                '${post.likesCount}',
                                style: const TextStyle(
                                  color: AppColors.error,
                                  fontSize: 10,
                                  fontWeight: FontWeight.w600,
                                ),
                              ),
                            ],
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
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
}
