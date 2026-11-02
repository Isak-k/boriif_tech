import 'dart:async';
import 'package:flutter/material.dart';
import '../core/theme/app_colors.dart';
import '../models/post_model.dart';
import '../core/routing/app_router.dart';
import 'cached_app_image.dart';

/// Horizontal widget displaying recent posts that scrolls horizontally continuously.
/// User can freely tap to open a post, or swipe manually, with auto-scroll resuming smoothly.
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
    // Continuous smooth marquee movement (~33fps)
    _autoScrollTimer = Timer.periodic(const Duration(milliseconds: 30), (timer) {
      if (!_scrollController.hasClients || _isUserInteracting) return;
      if (!_scrollController.position.hasContentDimensions) return;

      final maxScroll = _scrollController.position.maxScrollExtent;
      final currentScroll = _scrollController.offset;

      if (maxScroll <= 0) return;

      if (currentScroll >= maxScroll - 2) {
        _scrollController.jumpTo(0);
      } else {
        _scrollController.jumpTo(currentScroll + 0.9);
      }
    });
  }

  void _onUserInteractionStart() {
    _isUserInteracting = true;
    _resumeTimer?.cancel();
  }

  void _onUserInteractionEnd() {
    _resumeTimer?.cancel();
    _resumeTimer = Timer(const Duration(milliseconds: 2000), () {
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

    final recentPosts = widget.posts.take(10).toList();
    // Seamless infinite continuous loop
    final displayList = recentPosts.length > 1
        ? [...recentPosts, ...recentPosts, ...recentPosts, ...recentPosts]
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
                'Continuous Feed',
                style: TextStyle(
                  color: AppColors.cyan.withValues(alpha: 0.7),
                  fontSize: 11,
                  fontWeight: FontWeight.w500,
                ),
              ),
            ],
          ),
        ),

        // Continuous horizontal list with full visibility
        SizedBox(
          height: 182,
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
      width: 220,
      margin: const EdgeInsets.symmetric(horizontal: 6, vertical: 4),
      decoration: BoxDecoration(
        color: const Color(0xFF101622),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: AppColors.cyan.withValues(alpha: 0.25),
          width: 1,
        ),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.35),
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
                    height: 100,
                    width: double.infinity,
                    decoration: const BoxDecoration(
                      borderRadius: BorderRadius.vertical(top: Radius.circular(11)),
                    ),
                    child: CachedAppImage(
                      imageUrl: post.imageUrl,
                      width: double.infinity,
                      height: 100,
                      fit: BoxFit.cover,
                      borderRadius: const BorderRadius.vertical(top: Radius.circular(11)),
                      placeholderIcon: Icons.image_outlined,
                    ),
                  ),

                  // Post Code Badge (Top-left)
                  if (post.code.isNotEmpty)
                    Positioned(
                      top: 6,
                      left: 6,
                      child: Container(
                        padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2.5),
                        decoration: BoxDecoration(
                          color: const Color(0xDD000000),
                          borderRadius: BorderRadius.circular(4),
                          border: Border.all(
                            color: AppColors.cyan,
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
                ],
              ),

              // Title and metrics
              Expanded(
                child: Padding(
                  padding: const EdgeInsets.fromLTRB(10, 8, 10, 8),
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
                          fontSize: 13,
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
                                size: 13,
                                color: AppColors.cyan,
                              ),
                              const SizedBox(width: 4),
                              Text(
                                '${post.viewsCount}',
                                style: const TextStyle(
                                  color: AppColors.cyan,
                                  fontSize: 11,
                                  fontWeight: FontWeight.w600,
                                ),
                              ),
                            ],
                          ),
                          Row(
                            children: [
                              const Icon(
                                Icons.favorite,
                                size: 13,
                                color: AppColors.error,
                              ),
                              const SizedBox(width: 4),
                              Text(
                                '${post.likesCount}',
                                style: const TextStyle(
                                  color: AppColors.error,
                                  fontSize: 11,
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
}
